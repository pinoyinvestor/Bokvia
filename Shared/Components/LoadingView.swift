import SwiftUI

struct LoadingView: View {
    var message: String = ""
    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
