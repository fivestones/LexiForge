import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LearningViewModel()
    @State private var highlightedObject: LearningObject?
    @State private var itemSize: CGFloat = 0
    @State private var columns: Int = 1
    @State private var verticalSpacing: CGFloat = 0
    @State private var horizontalSpacing: CGFloat = 0

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack {
                        StatusBar(viewModel: viewModel)
                        
                        Spacer()
                            .frame(height: 40)

                        // Create the grid layout with the calculated number of columns
                        let gridItems = Array(repeating: GridItem(.fixed(itemSize), spacing: horizontalSpacing), count: columns)

                        // LazyVGrid to display objects in a grid
                        LazyVGrid(columns: gridItems, spacing: verticalSpacing) {
                            ForEach(viewModel.currentObjects, id: \.name) { object in
                                objectView(for: object)
                                    .frame(width: itemSize, height: itemSize) // Set the frame size for each object
                            }
                        }
                        .padding(.horizontal, horizontalSpacing) // Add horizontal padding to the grid

                        Spacer().frame(height: 70) // Add space to ensure content is not hidden behind the control bar
                    }
                }

                VStack {
                    Spacer()
                    ControlBar(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                }
            }
            .onAppear {
                // Use screen dimensions for initial layout calculation
                updateLayout(for: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                // Recalculate layout when size changes (orientation change)
                updateLayout(for: newSize)
            }
            .onReceive(viewModel.$highlightedObject) { object in
                highlightedObject = object
            }
        }
    }

    // Function to update layout based on available size
    func updateLayout(for size: CGSize) {
        let layout = calculateOptimalLayout(viewModel: viewModel, size: size)
        itemSize = layout.itemSize
        columns = layout.columns
        
        // Calculate the number of rows
        let rows = Int(ceil(Double(viewModel.objects.count) / Double(columns)))

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
        let objectCount = viewModel.objects.count // Get the total number of objects in viewModel.objects

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
    func objectView(for object: LearningObject) -> some View {
        Group {
            if let videoName = object.videoName {
                VideoPlayerView(videoName: videoName)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemSize, height: itemSize)
                    .clipped()
            } else if let imageName = object.imageName {
                Image(imageName)
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
                .stroke(highlightedObject == object ? Color.red : (viewModel.correctAnswerObjectWasSelected == object ? Color.green : Color.clear), lineWidth: 4)
        )
        .scaleEffect(highlightedObject == object || viewModel.correctAnswerObjectWasSelected == object ? 1.1 : 1.0)
//        .animation(.easeInOut(duration: 0.3), value: highlightedObject)
//        .animation(.easeInOut(duration: 0.3), value: viewModel.correctAnswerObjectWasSelected)
        .animation(.easeInOut, value: highlightedObject)
        .animation(.easeInOut, value: viewModel.correctAnswerObjectWasSelected)
        .opacity(viewModel.grayedOutObjects.contains(object) ? 0.2 : 1.0)
        .onTapGesture {
            if !viewModel.grayedOutObjects.contains(object) {
                viewModel.checkAnswer(selectedObject: object)
            }
        }
        .allowsHitTesting(!viewModel.grayedOutObjects.contains(object))
    }
}

struct StatusBar: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        ZStack{
            HStack{
                //left side of the StatusBar
                Spacer()
            }
            
            HStack{
                //Center of the StatusBar
                Text(viewModel.currentPrompt)
                .font(.title)
                .foregroundColor(.white)
            }

            HStack{
                //Right side of the StatusBar
                Spacer()
                Text("You can do it!")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.trailing)
            }
            
        }
        .padding()
        .background(Color.blue)
        .frame(height: 40) // Adjust height as needed
    }
}

//struct ControlBar: View {
//    @ObservedObject var viewModel: LearningViewModel
//
//    var body: some View {
//        HStack {
//            Button("अर्को वस्तु प्रस्तुत गर्नुहोस्") {
//                viewModel.introduceNextObject()
//            }
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//
//            Button("प्रश्न सोध्नुहोस्") {
//                viewModel.askQuestion()
//            }
//            .padding()
//            .background(Color.green)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//        }
//        .padding(.horizontal)
//        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) // Safe area inset for bottom
//    }
//}

struct ControlBar: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                // Action for first button
                viewModel.introduceNextObject()
            }) {
                Image(systemName: "plus.diamond")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
            }
            Spacer()
            Button(action: {
                // Action for second button
                viewModel.askQuestion()
            }) {
                Image(systemName: "questionmark.bubble")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
            }
            Spacer()
            Button(action: {
                // Action for third button
                
            }) {
                Image(systemName: "restart.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
            }
            .disabled(true)
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color.gray)
    }
}
