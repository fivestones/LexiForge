import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LearningViewModel()
    @State private var highlightedObject: LearningObject?

    var body: some View {
        VStack {
            Text(viewModel.currentPrompt)
                .font(.title)
                .padding()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(viewModel.currentObjects, id: \.name) { object in
                    if let videoName = object.videoName {
                        VideoPlayerView(videoName: videoName)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(12)
                            .shadow(color: .gray, radius: 4, x: 2, y: 2)
                            .border(Color.red, width: highlightedObject == object ? 4 : 0)
                            .scaleEffect(highlightedObject == object ? 1.1 : 1.0)
                            .animation(.easeInOut, value: highlightedObject)
                            .opacity(viewModel.grayedOutObjects.contains(object) ? 0.2 : 1.0) // Gray out
                            .allowsHitTesting(!viewModel.grayedOutObjects.contains(object)) // Disable interaction
                            .onTapGesture {
                                viewModel.checkAnswer(selectedObject: object)
                            }
                    } else if let imageName = object.imageName {
                        Button(action: {
                            viewModel.checkAnswer(selectedObject: object)
                        }) {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipped()
                                .cornerRadius(12)
                                .shadow(color: .gray, radius: 4, x: 2, y: 2)
                                .border(Color.red, width: highlightedObject == object ? 4 : 0)
                                .scaleEffect(highlightedObject == object ? 1.1 : 1.0)
                                .animation(.easeInOut, value: highlightedObject)
                                .opacity(viewModel.grayedOutObjects.contains(object) ? 0.2 : 1.0) // Gray out
                                .allowsHitTesting(!viewModel.grayedOutObjects.contains(object)) // Disable interaction
                        }
                    }
                }
            }
            .padding()

            Spacer()

            Button(action: {
                viewModel.introduceNextObject()
            }) {
                Text("अर्को वस्तु प्रस्तुत गर्नुहोस्")
            }
            .padding()

            Button(action: {
                viewModel.askQuestion()
            }) {
                Text("प्रश्न सोध्नुहोस्")
            }
            .padding()
        }
        .onReceive(viewModel.$highlightedObject) { object in
            highlightedObject = object
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
