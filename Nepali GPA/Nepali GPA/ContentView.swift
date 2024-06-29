import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LearningViewModel()
    @State private var highlightedObject: LearningObject?
    @State private var itemSize: CGFloat = 0
    
    let portraitColumns: Int = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Text(viewModel.currentPrompt)
                        .font(.title)
                        .padding()
                    
                    let columns = calculateColumns(for: geometry.size)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.currentObjects, id: \.name) { object in
                            objectView(for: object)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("अर्को वस्तु प्रस्तुत गर्नुहोस्") {
                        viewModel.introduceNextObject()
                    }
                    .padding()
                    
                    Button("प्रश्न सोध्नुहोस्") {
                        viewModel.askQuestion()
                    }
                    .padding()
                }
            }
        }
        .onReceive(viewModel.$highlightedObject) { object in
            highlightedObject = object
        }
        .onAppear {
            let screen = UIScreen.main.bounds
            let portraitWidth = min(screen.width, screen.height)
            itemSize = calculateItemSize(for: portraitWidth)
        }
    }
    
    func calculateItemSize(for width: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 32 // Adjust this value based on your layout
        let spacing: CGFloat = 16 * CGFloat(portraitColumns - 1)
        let availableWidth = width - horizontalPadding - spacing
        return availableWidth / CGFloat(portraitColumns)
    }
    
    func calculateColumns(for size: CGSize) -> [GridItem] {
        let columnCount = Int(size.width / (itemSize + 16))
        return Array(repeating: GridItem(.fixed(itemSize), spacing: 16), count: max(portraitColumns, columnCount))
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
