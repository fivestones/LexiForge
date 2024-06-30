import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LearningViewModel()
    @State private var highlightedObject: LearningObject?
    @State private var itemSize: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack {
                        Text(viewModel.currentPrompt)
                            .font(.title)
                            .padding()
                        
                        let layout = calculateLayout(for: geometry.size, objectCount: viewModel.currentObjects.count)
                        
                        LazyVGrid(columns: layout.columns, spacing: layout.verticalSpacing) {
                            ForEach(viewModel.currentObjects, id: \.name) { object in
                                objectView(for: object)
                            }
                        }
                        .padding(.horizontal, layout.horizontalPadding)
                        
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
        }
        .onReceive(viewModel.$highlightedObject) { object in
            highlightedObject = object
        }
        .onAppear {
            itemSize = calculateItemSize()
        }
    }
    
    func calculateItemSize() -> CGFloat {
        let screen = UIScreen.main.bounds
        let portraitWidth = min(screen.width, screen.height)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let baseColumnCount = isIPad ? 4 : 3
        let horizontalPadding: CGFloat = 32
        let spacing: CGFloat = 16 * CGFloat(baseColumnCount - 1)
        let availableWidth = portraitWidth - horizontalPadding - spacing
        return availableWidth / CGFloat(baseColumnCount)
    }
    
    func calculateLayout(for size: CGSize, objectCount: Int) -> (columns: [GridItem], verticalSpacing: CGFloat, horizontalPadding: CGFloat) {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = size.width > size.height
        
        var columnCount: Int
        var horizontalSpacing: CGFloat
        var verticalSpacing: CGFloat
        
        if isIPad {
            if isLandscape {
                columnCount = 4
                horizontalSpacing = 16
                verticalSpacing = 16
            } else {
                columnCount = objectCount > 12 ? 4 : 3
                if columnCount == 3 {
                    // Increase spacing for 3-column layout on iPad
                    let availableSpace = size.width - (itemSize * 3)
                    horizontalSpacing = availableSpace / 4  // Divide by 4 to get spacing between and on sides
                    verticalSpacing = horizontalSpacing
                } else {
                    horizontalSpacing = 16
                    verticalSpacing = 16
                }
            }
        } else {
            columnCount = isLandscape ? 6 : 3
            horizontalSpacing = 8
            verticalSpacing = 16
        }
        
        let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: horizontalSpacing), count: columnCount)
        let horizontalPadding = horizontalSpacing
        
        return (columns, verticalSpacing, horizontalPadding)
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

struct ControlBar: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        HStack {
            Button("अर्को वस्तु प्रस्तुत गर्नुहोस्") {
                viewModel.introduceNextObject()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("प्रश्न सोध्नुहोस्") {
                viewModel.askQuestion()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) // Safe area inset for bottom
    }
}
