import SwiftUI

struct ProviderClientsView: View {
    @Environment(AppState.self) private var appState
    @State private var clients: [ClientSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var activeFilter: ClientFilter = .all
    @State private var page = 1
    @State private var hasMore = true

    enum ClientFilter: String, CaseIterable {
        case all, vip, frequent, noShows, favorites, loyal

        func labelSv() -> String {
            switch self {
            case .all: return "Alla"
            case .vip: return "VIP"
            case .frequent: return "Frekventa"
            case .noShows: return "Uteblivna"
            case .favorites: return "Favoriter"
            case .loyal: return "Lojala"
            }
        }

        func labelEn() -> String {
            switch self {
            case .all: return "All"
            case .vip: return "VIP"
            case .frequent: return "Frequent"
            case .noShows: return "No-shows"
            case .favorites: return "Favorites"
            case .loyal: return "Loyal"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterPills

            // Built by Christos Ferlachidis & Daniel Hedenberg

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            if isLoading {
                LoadingView()
            } else if clients.isEmpty {
                emptyState
            } else {
                clientsList
            }
        }
        .navigationTitle(appState.isSv ? "Kunder" : "Clients")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadClients() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(appState.isSv ? "Sök kund..." : "Search client...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { Task { await loadClients() } }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadClients() }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel(appState.isSv ? "Rensa sökning" : "Clear search")
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClientFilter.allCases, id: \.self) { filter in
                    Button {
                        activeFilter = filter
                        Task { await loadClients() }
                    } label: {
                        Text(appState.isSv ? filter.labelSv() : filter.labelEn())
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(activeFilter == filter ? BokviaTheme.accent : Color(.secondarySystemBackground))
                            .foregroundStyle(activeFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel(appState.isSv ? filter.labelSv() : filter.labelEn())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(appState.isSv ? "Inga kunder hittades" : "No clients found")
                .font(.headline)
            Text(appState.isSv ? "Dina kunder visas här efter bokningar." : "Your clients will appear here after bookings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Clients List

    private var clientsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(clients) { client in
                    NavigationLink {
                        ProviderClientDetailView(clientUserId: client.userId)
                    } label: {
                        clientCard(client)
                    }
                    .foregroundStyle(.primary)
                    .onAppear {
                        if client.id == clients.last?.id && hasMore {
                            Task { await loadMore() }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func clientCard(_ client: ClientSummary) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: client.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(client.initials)
                            .font(.caption.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(client.fullName)
                        .font(.subheadline.weight(.semibold))
                    if client.isVip == true {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("VIP")
                    }
                }
                if let lastService = client.lastServiceName {
                    Text(lastService)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text("\(client.totalBookings ?? 0) \(appState.isSv ? "besök" : "visits")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let tags = client.tags, !tags.isEmpty {
                        Text(tags.prefix(2).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(BokviaTheme.accent)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Data Loading

    private func loadClients() async {
        isLoading = true
        errorMessage = nil
        page = 1
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var path = "/api/providers/me/clients?page=1&pageSize=\(Config.defaultPageSize)"
        if !query.isEmpty { path += "&search=\(query)" }
        if activeFilter != .all { path += "&filter=\(activeFilter.rawValue)" }

        do {
            let result = try await APIClient.shared.get(path, as: ClientListResponse.self)
            clients = result.items
            hasMore = result.hasMore
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda kunder." : "Failed to load clients."
        }
        isLoading = false
    }

    private func loadMore() async {
        page += 1
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var path = "/api/providers/me/clients?page=\(page)&pageSize=\(Config.defaultPageSize)"
        if !query.isEmpty { path += "&search=\(query)" }
        if activeFilter != .all { path += "&filter=\(activeFilter.rawValue)" }

        do {
            let result = try await APIClient.shared.get(path, as: ClientListResponse.self)
            clients.append(contentsOf: result.items)
            hasMore = result.hasMore
        } catch {
            page -= 1
            errorMessage = appState.isSv ? "Kunde inte ladda mer." : "Failed to load more."
        }
    }
}
