import SwiftUI

@main
struct VisionBoardIOSApp: App {
    @State private var toast = ToastCenter()
    @State private var visionBoard: VisionBoardStore
    @State private var savedProperties = SavedPropertiesStore()
    @State private var browse = BrowseStore()
    @State private var compare = CompareStore()
    @State private var location = LocationStore()
    @State private var aiSearch = AISearchStore()

    init() {
        let toast = ToastCenter()
        _toast = State(initialValue: toast)
        _visionBoard = State(initialValue: VisionBoardStore(toast: toast))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(visionBoard)
                .environment(toast)
                .environment(savedProperties)
                .environment(browse)
                .environment(compare)
                .environment(location)
                .environment(aiSearch)
        }
    }
}
