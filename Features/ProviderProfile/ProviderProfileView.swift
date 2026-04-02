import SwiftUI

struct ProviderProfileView: View {
    let slug: String
    @Environment(AppState.self) private var appState
    @State private var provider: ProviderProfile?
    @State private var services: [Service] = []
    @State private var works: [Work] = []
    @State private var reviews: [Review] = []
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var selectedTab: ProfileTab = .portfolio
    @State private var showBooking = false
    @State private var selectedService: Service?
    @State private var selectedWork: Work?

    enum ProfileTab: String, CaseIterable {
        case portfolio = "Portfolio"
        case services = "Tjänster"
        case reviews = "Omdömen"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                LoadingView()
            } else if let provider = provider {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        profileHeader(provider)

                        // Bio
                        if let bio = provider.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        // Built by Christos Ferlachidis & Daniel Hedenberg

                        // Follow + Chat buttons
                        HStack(spacing: 12) {
                            Button {
                                Task { await toggleFollow() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isFollowing ? "heart.fill" : "heart")
                                    Text(isFollowing ? "Följer" : "Följ")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isFollowing ? BokviaTheme.accent : Color(.secondarySystemBackground))
                                .foregroundStyle(isFollowing ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            NavigationLink {
                                ChatDetailView(userId: provider.id)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                    Text("Chatt")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .foregroundStyle(.primary)
                        }
                        .padding(.horizontal)

                        // Tab picker
                        Picker("", selection: $selectedTab) {
                            ForEach(ProfileTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Tab content
                        switch selectedTab {
                        case .portfolio:
                            if works.isEmpty {
                                ContentUnavailableView("Inget portfolio ännu", systemImage: "photo.on.rectangle")
                                    .frame(height: 200)
                            } else {
                                WorksGrid(works: works) { work in
                                    selectedWork = work
                                }
                                .navigationDestination(item: $selectedWork) { work in
                                    WorkDetailView(work: work)
                                }
                            }
                        case .services:
                            servicesList
                        case .reviews:
                            reviewsList
                        }
                    }
                    .padding(.bottom, 100)
                }

                // Sticky book button
                VStack {
                    Spacer()
                    Button {
                        showBooking = true
                    } label: {
                        Text(appState.isSv ? "Boka tid" : "Book appointment")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BokviaTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBooking) {
            if let provider = provider {
                NavigationStack {
                    BookingFlowView(
                        providerId: provider.id,
                        providerName: provider.displayName,
                        services: services
                    )
                }
            }
        }
        .task { await loadProfile() }
    }

    private func profileHeader(_ provider: ProviderProfile) -> some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(Text(String(provider.displayName.prefix(1))).font(.largeTitle.bold()).foregroundStyle(BokviaTheme.gray500))
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())

            HStack(spacing: 4) {
                Text(provider.displayName)
                    .font(.title3.bold())
                if provider.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(BokviaTheme.accent)
                        .accessibilityLabel(appState.isSv ? "Verifierad" : "Verified")
                }
            }

            if let city = provider.city {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(city)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if provider.reviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                        Text(provider.ratingFormatted)
                            .fontWeight(.semibold)
                        Text("(\(provider.reviewCount))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                HStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                    Text("\(works.count)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var servicesList: some View {
        LazyVStack(spacing: 0) {
            ForEach(services) { service in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.name(locale: appState.language))
                            .font(.subheadline.weight(.medium))
                        if let desc = service.description(locale: appState.language) {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        HStack(spacing: 8) {
                            Text(service.priceFormatted)
                                .font(.caption.weight(.medium))
                            if !service.durationFormatted.isEmpty {
                                Text("· \(service.durationFormatted)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Button(appState.isSv ? "Boka" : "Book") {
                        selectedService = service
                        showBooking = true
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding()
                Divider().padding(.leading)
            }
        }
    }

    private var reviewsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(review.customer?.firstName ?? "")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < review.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(i < review.rating ? .orange : .secondary)
                            }
                        }
                    }
                    if let text = review.text {
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
        }
    }

    private func loadProfile() async {
        do {
            async let providerResult = APIClient.shared.getNoAuth("/api/providers/slug/\(slug)", as: ProviderProfile.self)
            provider = try await providerResult

            if let pid = provider?.id {
                async let servicesResult: [Service] = try APIClient.shared.getNoAuth("/api/providers/\(pid)/services", as: [Service].self)
                async let worksResult: WorksExploreResponse = try APIClient.shared.getNoAuth("/api/works/provider/\(pid)", as: WorksExploreResponse.self)
                async let reviewsResult: ReviewsResponse = try APIClient.shared.getNoAuth("/api/reviews/provider/\(pid)", as: ReviewsResponse.self)

                services = (try? await servicesResult) ?? []
                works = (try? await worksResult)?.items ?? []
                reviews = (try? await reviewsResult)?.items ?? []

                if KeychainHelper.getAccessToken() != nil {
                    if let followCheck = try? await APIClient.shared.get("/api/follows/check/\(pid)", as: FollowCheckResponse.self) {
                        isFollowing = followCheck.isFollowing
                    }
                }
            }
        } catch {
            // Handle error
        }
        isLoading = false
    }

    private func toggleFollow() async {
        guard let pid = provider?.id else { return }
        if isFollowing {
            try? await APIClient.shared.delete("/api/follows/\(pid)")
        } else {
            struct Empty: Encodable {}
            _ = try? await APIClient.shared.post("/api/follows/\(pid)", body: Empty(), as: EmptyResponse.self)
        }
        isFollowing.toggle()
        HapticManager.light()
    }
}

struct FollowCheckResponse: Decodable {
    let isFollowing: Bool
}
