import SwiftUI

@main
struct MicrolearningApp: App {
    @StateObject private var viewModel = FeedViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                FeedView(viewModel: viewModel)
                    .tabItem {
                        Label("Feed", systemImage: "bolt.fill")
                    }

                SearchView(viewModel: viewModel)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }
            .tint(Color(hex: "4d9cff"))
            .preferredColorScheme(.dark)
        }
    }
}
