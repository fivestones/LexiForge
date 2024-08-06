import SwiftUI
import SwiftData
import AVFoundation

struct LearnSetView: View {
    @Binding var currentView: CurrentView
    
    @EnvironmentObject private var viewModel: LearningViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var highlightedObject: LearningObject?
    @State private var correctAnswerObjectWasSelected: LearningObject?
    @State private var introducingObject: LearningObject?
    @State private var introductionFinished: LearningObject?
    @State private var itemSize: CGFloat = 0
    @State private var columns: Int = 1
    @State private var verticalSpacing: CGFloat = 0
    @State private var horizontalSpacing: CGFloat = 0

    @State private var isAutoMode: Bool = false
    @State private var autoModeStep: Int = 0
    
    @State private var screenCenter: CGPoint = .zero
    @State private var scaleFactor: CGFloat = 2.0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    ScrollView {
                        VStack {
                            StatusBar(viewModel: viewModel, resetAnimationStates: resetAnimationStates)
                            
                            Spacer()
                                .frame(height: 40)

                            // Create the grid layout with the calculated number of columns
                            let gridItems = Array(repeating: GridItem(.fixed(itemSize), spacing: horizontalSpacing), count: columns)

                            // LazyVGrid to display objects in a grid
                            LazyVGrid(columns: gridItems, spacing: verticalSpacing) {
                                ForEach(viewModel.currentObjects, id: \.id) { object in
                                    objectView(for: object, screenCenter: screenCenter)
                                        .frame(width: itemSize, height: itemSize) // Set the frame size for each object
                                }
                            }
                            .padding(.horizontal, horizontalSpacing) // Add horizontal padding to the grid

                            Spacer().frame(height: 70) // Add space to ensure content is not hidden behind the control bar
                        }
                    }

                    VStack {
                        Spacer()
                        ControlBar(viewModel: viewModel, isAutoMode: $isAutoMode, autoModeStep: $autoModeStep, resetAnimationStates: resetAnimationStates)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .edgesIgnoringSafeArea(.all)
            .navigationBarItems(leading: Button("Close") {
                dismiss()
            })
            .onAppear {
                // Use screen dimensions for initial layout calculation
                updateLayout(for: geometry.size)
                screenCenter = CGPoint(
//                    x: geometry.size.width / 2,
//                    y: geometry.size.height / 2
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2
                )
                scaleFactor = calculateScaleFactor(screenSize: geometry.size, itemSize: itemSize)
            }
            .onChange(of: geometry.size) { newSize in
                // Recalculate layout when size changes (orientation change)
                updateLayout(for: newSize)
                scaleFactor = calculateScaleFactor(screenSize: newSize, itemSize: itemSize)
            }
            .onReceive(viewModel.$highlightedObject) { object in
                highlightedObject = object
            }
            .onReceive(viewModel.$introducingObject) { object in
                introducingObject = object
            }
            .onReceive(viewModel.$correctAnswerObjectWasSelected) { object in
                correctAnswerObjectWasSelected = object
            }
        }
    }

    // Function to update layout based on available size
    func updateLayout(for size: CGSize) {
        let layout = calculateOptimalLayout(viewModel: viewModel, size: size)
        itemSize = layout.itemSize
        columns = layout.columns
        
        // Calculate the number of rows
        let rows = Int(ceil(Double(viewModel.allObjects.count) / Double(columns)))

        // Calculate the optimal spacing
        let availableWidth = size.width// - 64 // Subtract horizontal padding
        let availableHeight = size.height - 70 - 60 //- 64 // Subtract button height, text height, and vertical padding

        if columns > 1 {
            horizontalSpacing = max((availableWidth - (CGFloat(columns) * itemSize)) / CGFloat(columns + 1), 0)
        } else {
            horizontalSpacing = 0
        }

        if rows > 1 {
            verticalSpacing = max((availableHeight - (CGFloat(rows) * itemSize)) / CGFloat(rows + 1), 0) // I changed to + 1 in CGFloat(rows + 1) instead of - 1 to account for padding at the edges.
        } else {
            verticalSpacing = 0
        }
    }

    // Unified calculateOptimalLayout function to take CGSize
    func calculateOptimalLayout(viewModel: LearningViewModel, size: CGSize) -> (itemSize: CGFloat, columns: Int) {
        // Constants for padding and other UI elements
        let horizontalPadding: CGFloat = 32 // Padding on the left and right sides
        let verticalPadding: CGFloat = 32 // Padding on the top and bottom sides
        let buttonHeight: CGFloat = 70 // Approximate height for the buttons at the bottom
        let textHeight: CGFloat = 60 // Approximate height for the text at the top

        // Determine the number of objects
        let objectCount = viewModel.allObjects.count // Get the total number of objects in viewModel.objects

        // Calculate available width and height
        let availableWidth = size.width - horizontalPadding
        let availableHeight = size.height - verticalPadding - buttonHeight - textHeight

        // Variables to store the optimal item size and number of columns
        var optimalItemSize: CGFloat = 0
        var optimalColumns: Int = 1

        // Iterate through possible column counts to find the optimal layout
        for columns in 1...objectCount {
            let rows = Int(ceil(Double(objectCount) / Double(columns))) // Calculate the number of rows for the current column count

            // Calculate the item size without spacing
            let itemWidth = availableWidth / CGFloat(columns)
            let itemHeight = availableHeight / CGFloat(rows)

            // Determine the smaller of the two dimensions to ensure square items
            let baseItemSize = min(itemWidth, itemHeight)

            // Calculate spacing as a percentage of the base item size
            let spacingPercentage: CGFloat = 0.1 // 5% of the item size for spacing
            let spacing = baseItemSize * spacingPercentage

            // Adjust the item size to account for spacing
            let adjustedItemSize = baseItemSize - spacing

            // Check if the adjusted item size is larger than the current optimal item size
            if adjustedItemSize > optimalItemSize && rows <= Int(size.height / adjustedItemSize) && columns <= Int(size.width / adjustedItemSize) {
                optimalItemSize = adjustedItemSize // Update the optimal item size
                optimalColumns = columns // Update the optimal number of columns
            }
        }

        // Return the optimal item size and number of columns
        return (optimalItemSize, optimalColumns)
    }

    @ViewBuilder
    func objectView(for object: LearningObject, screenCenter: CGPoint) -> some View {
        @State var offset: CGSize = .zero
        
        GeometryReader { geometry in
            ZStack {
                if let videoName = object.videoName {
                    VideoPlayerView(videoName: videoName)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemSize, height: itemSize)
                        .clipped()
                } else if let imageName = object.imageName {
                    Image(uiImage: loadImage(named: imageName))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemSize, height: itemSize)
                        .clipped()
                }
            }
            .cornerRadius(12)
            .shadow(color: .gray, radius: 4, x: 2, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(highlightedObject == object ? Color.red : (correctAnswerObjectWasSelected == object ? Color.green : Color.clear), lineWidth: 4)
            )
            .scaleEffect(introducingObject == object ? scaleFactor : 1.0)
            .offset(introducingObject == object ? CGSize(
                width: screenCenter.x - geometry.frame(in: .global).midX,
                height: screenCenter.y - geometry.frame(in: .global).midY
            ) : offset)
            .scaleEffect(highlightedObject == object || correctAnswerObjectWasSelected == object ? 1.1 : 1.0)
            .animation(.easeInOut, value: highlightedObject)
            .animation(.easeInOut, value: correctAnswerObjectWasSelected)
            .shadow(color: introducingObject == object ? .primary : .clear, radius: introducingObject == object ? 70 : 0)
            .animation(.easeOut, value: introducingObject)
            .opacity(viewModel.grayedOutObjects.contains(object) ? 0.2 : 1.0)
            .contentShape(Rectangle()) // Ensure only the visible part is tappable
            .onTapGesture {
                if !viewModel.grayedOutObjects.contains(object) {
                    if introducingObject == nil {
                        viewModel.checkAnswer(selectedObject: object)
                        resetAnimationStates()
                    }
                }
            }
            .allowsHitTesting(!viewModel.grayedOutObjects.contains(object))
        }
    }
    
    func calculateScaleFactor(screenSize: CGSize, itemSize: CGFloat) -> CGFloat {
        let targetSize = min(screenSize.width, screenSize.height) * 0.8
        return targetSize / itemSize
    }
    
    func resetAnimationStates() {
        print("Resetting animation states")
        highlightedObject = nil
        correctAnswerObjectWasSelected = nil
        introducingObject = nil
    }

    func loadImage(named: String) -> UIImage {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(named)
//        print("Loading image from path: \(fileURL.path)")
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
//            print("Loaded image successfully: \(named)")
            return image
        }
        print("Failed to load image: \(named)")
        return UIImage(systemName: "photo")!
    }

}

struct StatusBar: View {
    @ObservedObject var viewModel: LearningViewModel
    let resetAnimationStates: () -> Void
    
    var body: some View {
        ZStack{
            HStack{
                Spacer()
            }
            HStack{
                Text(viewModel.currentPrompt)
                .font(.title)
                .foregroundColor(.white)
                .onTapGesture {
                    resetAnimationStates()
                    viewModel.replayCurrentPrompt()
                }
            }
            HStack{
                Spacer()
                Text("")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.trailing)
                .onTapGesture {
                    resetAnimationStates()
                }
            }
        }
        .padding()
        .background(Color.blue)
        .frame(height: 40)
    }
}

struct ControlBar: View {
    @ObservedObject var viewModel: LearningViewModel
    @Binding var isAutoMode: Bool
    @Binding var autoModeStep: Int
    let resetAnimationStates: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                print("tapped on plus.diamond, going to introduce next object")
                resetAnimationStates()
                viewModel.introduceNextObject(completion: {})
            }) {
                Image(systemName: "plus.diamond")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue)
            }
            Button(action: {
                resetAnimationStates()
                viewModel.askQuestion(completion: {})
            }) {
                Image(systemName: "questionmark.bubble")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green)
            }
            Button(action: {
                resetAnimationStates()
                viewModel.shuffleCurrentObjects()
            }) {
                Image(systemName: "restart.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
            }
            Button(action: {
                resetAnimationStates()
                viewModel.isAutoMode = true
                viewModel.autoModeStep = 0
                viewModel.continueAutoMode()
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.orange)
            }
            Button(action: {
                resetAnimationStates()
                // Repeat action to be implemented
            }) {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.purple)
            }
            Button(action: {
                resetAnimationStates()
                viewModel.isAutoMode = false
            }) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
            }
        }
        .frame(height: 50)
        .background(Color.gray)
    }
}
