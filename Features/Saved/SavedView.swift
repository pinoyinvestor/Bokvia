import SwiftUI

struct SavedView: View {
    @Environment(AppState.self) private var appState
    @State private var works: [Work] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if works.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga sparade" : "No saved items",
                    systemImage: "bookmark",
                    description: Text(appState.isSv ? "Spara arbeten du gillar" : "Save works you like")
                )
            } else {
                // Built by Christos Ferlachidis & Daniel Hedenberg
                ScrollView {
                    WorksGrid(works: works) { work in
                        // Show work detail
                    }
                }
            }
        }
        .navigationTitle(appState.isSv ? "Sparade" : "Saved")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        if let result = try? await APIClient.shared.get("/api/works/saved", as: WorksExploreResponse.self) {
            works = result.items
        }
        isLoading = false
    }
}
