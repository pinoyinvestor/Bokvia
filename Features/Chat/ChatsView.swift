import SwiftUI

struct ChatsView: View {
    @Environment(AppState.self) private var appState
    @State private var chats: [Chat] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showBlockConfirm = false
    @State private var chatToBlock: Chat?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = errorMessage {
                ContentUnavailableView(
                    appState.isSv ? "Något gick fel" : "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if chats.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga meddelanden" : "No messages",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text(appState.isSv ? "Starta en chatt från en profil" : "Start a chat from a profile")
                )
            } else {
                List(chats) { chat in
                    NavigationLink {
                        ChatDetailView(chatId: chat.id)
                    } label: {
                        chatRow(chat)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            chatToBlock = chat
                            showBlockConfirm = true
                        } label: {
                            Label(appState.isSv ? "Blockera" : "Block", systemImage: "person.slash")
                        }
                    }
                }
                // Built by Christos Ferlachidis & Daniel Hedenberg
                .listStyle(.plain)
            }
        }
        .navigationTitle(appState.isSv ? "Chatt" : "Chat")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if chats.contains(where: { ($0.unreadCount ?? 0) > 0 }) {
                    Button(appState.isSv ? "Markera alla lästa" : "Mark all read") {
                        Task { await markAllRead() }
                    }
                    .font(.caption)
                }
            }
        }
        .task { await loadChats() }
        .refreshable { await loadChats() }
        .confirmationDialog(
            appState.isSv ? "Blockera denna användare?" : "Block this user?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button(appState.isSv ? "Blockera" : "Block", role: .destructive) {
                if let chat = chatToBlock {
                    blockUserFromChat(chat)
                }
            }
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) { chatToBlock = nil }
        } message: {
            Text(appState.isSv ? "Du kommer inte längre att kunna ta emot meddelanden från denna person." : "You will no longer receive messages from this person.")
        }
    }

    private func chatRow(_ chat: Chat) -> some View {
        HStack(spacing: 12) {
            let other = chat.otherParticipant
            AsyncImage(url: URL(string: other?.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(Text(other?.initials ?? "?").font(.caption.bold()).foregroundStyle(BokviaTheme.gray500))
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(other?.fullName ?? "")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let time = chat.updatedAt {
                        Text(timeAgo(time))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(chat.lastMessage?.text ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let count = chat.unreadCount, count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BokviaTheme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(_ isoDate: String) -> String {
        guard let date = DateFormatter.apiDateTime.date(from: isoDate) else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Nu" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }

    private func loadChats() async {
        errorMessage = nil
        do {
            chats = try await APIClient.shared.get("/api/chat", as: [Chat].self)
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda chattar." : "Failed to load chats."
        }
        isLoading = false
    }

    private func markAllRead() async {
        for chat in chats where (chat.unreadCount ?? 0) > 0 {
            struct Empty: Encodable {}
            _ = try? await APIClient.shared.patch("/api/chat/\(chat.id)/read", body: Empty(), as: EmptyResponse.self)
        }
        await loadChats()
    }

    private func blockUserFromChat(_ chat: Chat) {
        guard let other = chat.otherParticipant else { return }
        Task {
            struct Empty: Encodable {}
            _ = try? await APIClient.shared.post("/api/users/\(other.userId)/block", body: Empty(), as: EmptyResponse.self)
            HapticManager.light()
            chats.removeAll { $0.id == chat.id }
            chatToBlock = nil
        }
    }
}
