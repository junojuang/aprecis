import SwiftUI

@main
struct MicrolearningApp: App {
    var body: some Scene {
        WindowGroup {
            FeedView()
                .preferredColorScheme(.dark)
        }
    }
}
