import SwiftUI

struct ProviderMyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var provider: ProviderMeResponse?
    @State private var services: [Service] = []
    @State private var works: [Work] = []
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: ProfileTab = .portfolio
    @State private var showEditProfile = false
    @State private var selectedWork: Work?

    enum ProfileTab: String, CaseIterable {
        case portfolio, services, reviews
        func label(isSv: Bool) -> String {
            switch self {
            case .portfolio: return "Portfolio"
            case .services: return isSv ? "Tjänster" : "Services"
            case .reviews: return isSv ? "Omdömen" : "Reviews"
            }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = errorMessage, provider == nil {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let provider = provider {
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader(provider)

                        if let bio = provider.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        // Built by Christos Ferlachidis & Daniel Hedenberg

                        editButton

                        tabPicker
                        tabContent
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Min profil" : "My profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadProfile() }
        .refreshable { await loadProfile() }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                ProviderEditProfileView()
            }
        }
        .onChange(of: showEditProfile) { _, isShowing in
            if !isShowing { Task { await loadProfile() } }
        }
    }

    // MARK: - Profile Header

    private func profileHeader(_ provider: ProviderMeResponse) -> some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(provider.displayName.prefix(1)))
                            .font(.largeTitle.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
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
                        Text(String(format: "%.1f", provider.ratingAvg))
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

            if let mode = provider.bookingMode {
                HStack(spacing: 4) {
                    Image(systemName: mode == "INSTANT" ? "bolt.fill" : "hand.raised.fill")
                        .font(.caption2)
                    Text(mode == "INSTANT"
                        ? (appState.isSv ? "Autobokning" : "Auto-book")
                        : (appState.isSv ? "Manuell bokning" : "Manual booking"))
                        .font(.caption)
                }
                .foregroundStyle(BokviaTheme.accent)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Edit Button

    private var editButton: some View {
        Button {
            showEditProfile = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "pencil")
                Text(appState.isSv ? "Redigera profil" : "Edit profile")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(BokviaTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .accessibilityLabel(appState.isSv ? "Redigera profil" : "Edit profile")
    }

    // MARK: - Tabs

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Text(tab.label(isSv: appState.isSv)).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .portfolio:
            if works.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inget portfolio ännu" : "No portfolio yet",
                    systemImage: "photo.on.rectangle"
                )
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

    // MARK: - Data Loading

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIClient.shared.get("/api/providers/me", as: ProviderMeResponse.self)
            provider = result

            async let servicesResult: [Service] = try APIClient.shared.get("/api/providers/\(result.id)/services", as: [Service].self)
            async let worksResult: WorksExploreResponse = try APIClient.shared.getNoAuth("/api/works/provider/\(result.id)", as: WorksExploreResponse.self)
            async let reviewsResult: ReviewsResponse = try APIClient.shared.getNoAuth("/api/reviews/provider/\(result.id)", as: ReviewsResponse.self)

            services = (try? await servicesResult) ?? []
            works = (try? await worksResult)?.items ?? []
            reviews = (try? await reviewsResult)?.items ?? []
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda profilen." : "Failed to load profile."
        }
        isLoading = false
    }
}
