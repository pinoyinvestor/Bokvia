import SwiftUI
import Combine

struct SalonTeamView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: TeamTab = .team
    @State private var members: [SalonTeamMember] = []
    @State private var invites: [SalonInvite] = []
    @State private var searchResults: [SearchProviderResult] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    enum TeamTab: String, CaseIterable {
        case team, search, requests

        func label(isSv: Bool) -> String {
            switch self {
            case .team: return isSv ? "Team" : "Team"
            case .search: return isSv ? "Sök" : "Search"
            case .requests: return isSv ? "Förfrågningar" : "Requests"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(TeamTab.allCases, id: \.self) { tab in
                    Text(tab.label(isSv: appState.isSv)).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .team { Task { await loadTeam() } }
                else if newTab == .requests { Task { await loadInvites() } }
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            switch selectedTab {
            case .team:
                teamList
            case .search:
                searchView
            case .requests:
                requestsList
            }
        }
        .navigationTitle(appState.isSv ? "Team" : "Team")
        .task { await loadTeam() }
        .refreshable {
            switch selectedTab {
            case .team: await loadTeam()
            case .search: break
            case .requests: await loadInvites()
            }
        }
    }

    // MARK: - Team List

    private var teamList: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if members.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga teammedlemmar" : "No team members",
                    systemImage: "person.3"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(members) { member in
                            memberRow(member)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func memberRow(_ member: SalonTeamMember) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: member.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(member.displayName.prefix(1)))
                            .font(.caption.bold())
                            .foregroundStyle(BokviaTheme.accent)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.subheadline.weight(.semibold))
                if member.reviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", member.ratingAvg))
                            .font(.caption)
                        Text("(\(member.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Salon pricing indicator
            if let usesSalonPricing = member.usesSalonPricing {
                Text(usesSalonPricing
                     ? (appState.isSv ? "Salongpris" : "Salon price")
                     : (appState.isSv ? "Eget pris" : "Own price"))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(usesSalonPricing ? BokviaTheme.accentLight : Color(.tertiarySystemBackground))
                    .foregroundStyle(usesSalonPricing ? BokviaTheme.accent : .secondary)
                    .clipShape(Capsule())
            }

            // Remove button
            Button(role: .destructive) {
                Task { await removeMember(member.id) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.6))
            }
            .accessibilityLabel(appState.isSv ? "Ta bort medlem" : "Remove member")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Search View

    private var searchView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    appState.isSv ? "Sök frisör att bjuda in..." : "Search provider to invite...",
                    text: $searchText
                )
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    debounceSearch(newValue)
                }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom, 8)

            if isSearching {
                LoadingView()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga resultat" : "No results",
                    systemImage: "magnifyingglass"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(searchResults) { provider in
                            searchResultRow(provider)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func searchResultRow(_ provider: SearchProviderResult) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(provider.displayName.prefix(1)))
                            .font(.caption.bold())
                            .foregroundStyle(BokviaTheme.accent)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    if let city = provider.city {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if provider.reviewCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", provider.ratingAvg))
                                .font(.caption)
                        }
                    }
                }
            }

            Spacer()

            Button {
                Task { await inviteProvider(provider.id) }
            } label: {
                Text(appState.isSv ? "Bjud in" : "Invite")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(appState.isSv ? "Bjud in \(provider.displayName)" : "Invite \(provider.displayName)")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Requests List

    private var requestsList: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if invites.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga förfrågningar" : "No requests",
                    systemImage: "envelope"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(invites) { invite in
                            inviteRow(invite)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func inviteRow(_ invite: SalonInvite) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: invite.providerAvatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(invite.providerName?.prefix(1) ?? "?"))
                            .font(.caption.bold())
                            .foregroundStyle(BokviaTheme.accent)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.providerName ?? (appState.isSv ? "Okänd" : "Unknown"))
                    .font(.subheadline.weight(.semibold))
                Text(invite.status.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if invite.status == "PENDING" {
                HStack(spacing: 8) {
                    Button {
                        Task { await respondToInvite(invite.id, accept: false) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(appState.isSv ? "Avböj" : "Decline")

                    Button {
                        Task { await respondToInvite(invite.id, accept: true) }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(appState.isSv ? "Acceptera" : "Accept")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await searchProviders(query)
        }
    }

    private func searchProviders(_ query: String) async {
        isSearching = true
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let result = try? await APIClient.shared.get(
            "/api/providers/search?q=\(encoded)", as: SearchProvidersResponse.self
        ) {
            searchResults = result.items
        }
        isSearching = false
    }

    private func inviteProvider(_ providerId: String) async {
        let body = SendInviteRequest(providerId: providerId)
        _ = try? await APIClient.shared.post("/api/salons/me/send-invite", body: body, as: EmptyResponse.self)
        HapticManager.medium()
        // Remove from search results after invite
        searchResults.removeAll { $0.id == providerId }
    }

    private func removeMember(_ providerId: String) async {
        try? await APIClient.shared.delete("/api/salons/me/team/\(providerId)")
        members.removeAll { $0.id == providerId }
        HapticManager.medium()
    }

    private func respondToInvite(_ inviteId: String, accept: Bool) async {
        struct Body: Encodable { let accept: Bool }
        _ = try? await APIClient.shared.post("/api/salons/me/invites/\(inviteId)/respond", body: Body(accept: accept), as: EmptyResponse.self)
        HapticManager.medium()
        await loadInvites()
    }

    private func loadTeam() async {
        isLoading = true
        if let result = try? await APIClient.shared.get("/api/salons/me/team", as: SalonTeamResponse.self) {
            members = result.items
        }
        isLoading = false
    }

    private func loadInvites() async {
        isLoading = true
        if let result = try? await APIClient.shared.get("/api/salons/me/invites", as: SalonInvitesResponse.self) {
            invites = result.items
        }
        isLoading = false
    }
}
