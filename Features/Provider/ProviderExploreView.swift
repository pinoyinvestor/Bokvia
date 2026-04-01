import SwiftUI

struct ProviderExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: ExploreTab = .findSalon
    @State private var salons: [DiscoverSalon] = []
    @State private var invites: [SalonInvite] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var activeCategory: String?
    @State private var selectedSalon: DiscoverSalon?
    @State private var showSalonDetail = false

    enum ExploreTab: String, CaseIterable {
        case findSalon, inspiration
        func label(isSv: Bool) -> String {
            switch self {
            case .findSalon: return isSv ? "Hitta salong" : "Find salon"
            case .inspiration: return "Inspiration"
            }
        }
    }

    private let categoryOptions = [
        ("hair", "Hår", "Hair"),
        ("nails", "Naglar", "Nails"),
        ("lashes", "Fransar", "Lashes"),
        ("skin", "Hud", "Skin"),
        ("tattoo", "Tatuering", "Tattoo"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            tabPicker

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            switch selectedTab {
            case .findSalon:
                findSalonContent
            case .inspiration:
                inspirationContent
            }
        }
        .navigationTitle(appState.isSv ? "Utforska" : "Explore")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .sheet(isPresented: $showSalonDetail) {
            if let salon = selectedSalon {
                salonDetailSheet(salon)
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ExploreTab.allCases, id: \.self) { tab in
                Text(tab.label(isSv: appState.isSv)).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onChange(of: selectedTab) { _, _ in
            Task { await loadData() }
        }
    }

    // MARK: - Find Salon Tab

    private var findSalonContent: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(appState.isSv ? "Sök salong..." : "Search salon...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await searchSalons() } }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await loadSalons() }
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

            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categoryOptions, id: \.0) { slug, sv, en in
                        Button {
                            activeCategory = activeCategory == slug ? nil : slug
                            Task { await loadSalons() }
                        } label: {
                            Text(appState.isSv ? sv : en)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(activeCategory == slug ? BokviaTheme.accent : Color(.secondarySystemBackground))
                                .foregroundStyle(activeCategory == slug ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel(appState.isSv ? sv : en)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Invites section
            if !invites.isEmpty {
                invitesSection
            }

            // Salon list
            if isLoading {
                LoadingView()
            } else if salons.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(appState.isSv ? "Inga salonger hittades" : "No salons found")
                        .font(.headline)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(salons) { salon in
                            Button {
                                selectedSalon = salon
                                showSalonDetail = true
                            } label: {
                                salonCard(salon)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Invites Section

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.isSv ? "Inbjudningar" : "Invitations")
                .font(.headline)
                .padding(.horizontal)

            ForEach(invites) { invite in
                inviteCard(invite)
            }
        }
        .padding(.vertical, 8)
    }

    private func inviteCard(_ invite: SalonInvite) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: invite.salonLogoUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8).fill(BokviaTheme.gray200)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(invite.salonName)
                        .font(.subheadline.weight(.semibold))
                    if let city = invite.salonCity {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let msg = invite.message {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                if let chair = invite.chairPrice {
                    Text(appState.isSv ? "Stol: \(Int(chair)) kr/mån" : "Chair: \(Int(chair)) kr/mo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let commission = invite.commissionPercent {
                    Text(appState.isSv ? "Provision: \(Int(commission))%" : "Commission: \(Int(commission))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    Task { await acceptInvite(invite.id, pricingChoice: "CHAIR") }
                } label: {
                    Text(appState.isSv ? "Acceptera (Stol)" : "Accept (Chair)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel(appState.isSv ? "Acceptera med stolshyra" : "Accept with chair rent")

                Button {
                    Task { await acceptInvite(invite.id, pricingChoice: "COMMISSION") }
                } label: {
                    Text(appState.isSv ? "Acceptera (Provision)" : "Accept (Commission)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(BokviaTheme.accentLight)
                        .foregroundStyle(BokviaTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel(appState.isSv ? "Acceptera med provision" : "Accept with commission")

                Button {
                    Task { await declineInvite(invite.id) }
                } label: {
                    Text(appState.isSv ? "Neka" : "Decline")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel(appState.isSv ? "Neka inbjudan" : "Decline invitation")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Salon Card

    private func salonCard(_ salon: DiscoverSalon) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: salon.logoUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10).fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(salon.name.prefix(1)))
                            .font(.title3.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.subheadline.weight(.semibold))
                if let city = salon.city {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(city)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    if let chairs = salon.availableChairs, chairs > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "chair")
                                .font(.caption2)
                            Text("\(chairs)")
                                .font(.caption)
                        }
                        .foregroundStyle(.green)
                    }
                    if let count = salon.providerCount {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2")
                                .font(.caption2)
                            Text("\(count)")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    if salon.reviewCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", salon.ratingAvg))
                                .font(.caption)
                        }
                    }
                }
            }

            Spacer()

            if salon.seekingTalent == true {
                Text(appState.isSv ? "Söker" : "Hiring")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Salon Detail Sheet

    private func salonDetailSheet(_ salon: DiscoverSalon) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: salon.logoUrl ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16).fill(BokviaTheme.gray200)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text(salon.name)
                        .font(.title3.bold())

                    if let city = salon.city {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(city)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        if salon.reviewCount > 0 {
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                    Text(String(format: "%.1f", salon.ratingAvg))
                                        .fontWeight(.semibold)
                                }
                                Text("\(salon.reviewCount) \(appState.isSv ? "omdömen" : "reviews")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let count = salon.providerCount {
                            VStack(spacing: 2) {
                                Text("\(count)")
                                    .fontWeight(.semibold)
                                Text(appState.isSv ? "frisörer" : "providers")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let chairs = salon.availableChairs {
                            VStack(spacing: 2) {
                                Text("\(chairs)")
                                    .fontWeight(.semibold)
                                Text(appState.isSv ? "lediga stolar" : "available chairs")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await requestJoin(salon.id) }
                    } label: {
                        Label(appState.isSv ? "Skicka förfrågan" : "Request to join", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BokviaTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .accessibilityLabel(appState.isSv ? "Skicka förfrågan att gå med" : "Request to join salon")
                }
                .padding()
            }
            .navigationTitle(salon.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.isSv ? "Stäng" : "Close") { showSalonDetail = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Inspiration Tab

    private var inspirationContent: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(BokviaTheme.accent)
            Text(appState.isSv ? "Inspiration kommer snart" : "Inspiration coming soon")
                .font(.headline)
            Text(appState.isSv ? "Upptäck trender och populära salonger." : "Discover trends and popular salons.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func acceptInvite(_ inviteId: String, pricingChoice: String) async {
        do {
            _ = try await APIClient.shared.post(
                "/api/salons/provider-invites/\(inviteId)/accept",
                body: InviteActionBody(pricingChoice: pricingChoice),
                as: EmptyResponse.self
            )
            invites.removeAll { $0.id == inviteId }
            HapticManager.success()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte acceptera inbjudan." : "Failed to accept invitation."
            HapticManager.error()
        }
    }

    private func declineInvite(_ inviteId: String) async {
        do {
            _ = try await APIClient.shared.post(
                "/api/salons/provider-invites/\(inviteId)/decline",
                body: InviteActionBody(pricingChoice: nil),
                as: EmptyResponse.self
            )
            invites.removeAll { $0.id == inviteId }
            HapticManager.light()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte neka inbjudan." : "Failed to decline invitation."
        }
    }

    private func requestJoin(_ salonId: String) async {
        struct JoinBody: Encodable { let salonId: String }
        do {
            _ = try await APIClient.shared.post("/api/salons/join-request", body: JoinBody(salonId: salonId), as: EmptyResponse.self)
            HapticManager.success()
            showSalonDetail = false
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skicka förfrågan." : "Failed to send request."
            HapticManager.error()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        switch selectedTab {
        case .findSalon:
            await loadSalons()
            await loadInvites()
        case .inspiration:
            break
        }
        isLoading = false
    }

    private func loadSalons() async {
        let loc = LocationManager.shared
        var path = "/api/salons/discover?lat=\(loc.latitude)&lng=\(loc.longitude)"
        if let cat = activeCategory { path += "&category=\(cat)" }
        do {
            let result = try await APIClient.shared.getNoAuth(path, as: [DiscoverSalon].self)
            salons = result
        } catch {
            salons = []
            errorMessage = appState.isSv ? "Kunde inte ladda salonger." : "Failed to load salons."
        }
    }

    private func searchSalons() async {
        guard !searchText.isEmpty else { await loadSalons(); return }
        isLoading = true
        let q = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        do {
            let result = try await APIClient.shared.getNoAuth("/api/salons/search?q=\(q)", as: [DiscoverSalon].self)
            salons = result
        } catch {
            errorMessage = appState.isSv ? "Sökningen misslyckades." : "Search failed."
        }
        isLoading = false
    }

    private func loadInvites() async {
        invites = (try? await APIClient.shared.get("/api/salons/provider-invites", as: [SalonInvite].self)) ?? []
    }
}
