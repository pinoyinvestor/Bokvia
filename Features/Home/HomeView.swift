import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var feed: HomeFeed?
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var nextBooking: Booking?

    private let categories: [(emoji: String, key: String, slug: String)] = [
        ("💇", "Hår", "hair"),
        ("💅", "Naglar", "nails"),
        ("👁️", "Fransar", "lashes"),
        ("🧴", "Hud", "skin"),
        ("🎨", "Tatuering", "tattoo"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.title2.bold())
                        if let city = LocationManager.shared.city {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption2)
                                Text(city)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    avatarView
                }
                .padding(.horizontal)

                // Family member switcher
                if !appState.familyMembers.isEmpty {
                    familyPills
                }

                // Built by Christos Ferlachidis & Daniel Hedenberg

                // Search bar
                NavigationLink {
                    ExploreView(initialSearch: searchText)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(appState.isSv ? "Sök frisör, salong..." : "Search provider, salon...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.slug) { cat in
                            NavigationLink {
                                ExploreView(initialCategory: cat.slug)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(cat.emoji)
                                        .font(.title2)
                                    Text(cat.key)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                                .frame(width: 70, height: 70)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Next booking
                if let booking = nextBooking {
                    nextBookingCard(booking)
                }

                // Sections from feed
                if isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if let feed = feed {
                    if let following = feed.following, !following.isEmpty {
                        sectionHeader(appState.isSv ? "Följer" : "Following")
                        providerRow(following)
                    }

                    if let trending = feed.trending, !trending.isEmpty {
                        sectionHeader(appState.isSv ? "Populärt denna vecka" : "Trending this week")
                        providerRow(trending)
                    }

                    if let nearby = feed.nearby, !nearby.isEmpty {
                        sectionHeader(appState.isSv ? "Nära dig" : "Near you")
                        providerRow(nearby)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.currentUser?.firstName ?? ""
        let prefix: String
        if hour < 10 { prefix = appState.isSv ? "God morgon" : "Good morning" }
        else if hour < 18 { prefix = appState.isSv ? "Hej" : "Hi" }
        else { prefix = appState.isSv ? "God kväll" : "Good evening" }
        return name.isEmpty ? prefix : "\(prefix), \(name)"
    }

    private var avatarView: some View {
        AsyncImage(url: URL(string: appState.currentUser?.avatarUrl ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(BokviaTheme.accentLight)
                .overlay(
                    Text(appState.currentUser?.initials ?? "?")
                        .font(.subheadline.bold())
                        .foregroundStyle(BokviaTheme.accent)
                )
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .accessibilityLabel(appState.isSv ? "Profilbild" : "Profile picture")
    }

    private var familyPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text(appState.isSv ? "Bokar för:" : "Booking for:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    appState.switchBookingProfile(nil)
                } label: {
                    Text(appState.currentUser?.firstName ?? (appState.isSv ? "Jag" : "Me"))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(appState.activeBookingProfile == nil ? BokviaTheme.accent : Color(.secondarySystemBackground))
                        .foregroundStyle(appState.activeBookingProfile == nil ? .white : .primary)
                        .clipShape(Capsule())
                }

                ForEach(appState.familyMembers) { member in
                    Button {
                        appState.switchBookingProfile(member)
                    } label: {
                        Text(member.name)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(appState.activeBookingProfile?.id == member.id ? BokviaTheme.accent : Color(.secondarySystemBackground))
                            .foregroundStyle(appState.activeBookingProfile?.id == member.id ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func nextBookingCard(_ booking: Booking) -> some View {
        NavigationLink {
            BookingDetailView(booking: booking)
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: booking.provider?.avatarUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(BokviaTheme.gray200)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isSv ? "Nästa bokning" : "Next booking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(booking.provider?.displayName ?? "")
                        .font(.subheadline.weight(.semibold))
                    Text("\(booking.date) · \(booking.startTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: booking.status)
            }
            .padding()
            .background(BokviaTheme.accentLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    private func providerRow(_ providers: [DiscoverProvider]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(providers) { provider in
                    NavigationLink {
                        ProviderProfileView(slug: provider.slug)
                    } label: {
                        compactProviderCard(provider)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    private func compactProviderCard(_ provider: DiscoverProvider) -> some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text(provider.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if provider.reviewCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", provider.ratingAvg))
                        .font(.caption2)
                }
                .accessibilityLabel("Rating \(String(format: "%.1f", provider.ratingAvg)) out of 5")
            }
        }
        .frame(width: 90)
    }

    private func loadData() async {
        let loc = LocationManager.shared
        let lat = loc.hasLocation ? loc.latitude : Config.defaultLatitude
        let lng = loc.hasLocation ? loc.longitude : Config.defaultLongitude

        async let feedResult: HomeFeed? = try? await APIClient.shared.get(
            "/api/feed/home?lat=\(lat)&lng=\(lng)&radius=\(Config.feedRadius)",
            as: HomeFeed.self
        )
        async let nextResult: NextBookingResponse? = try? await APIClient.shared.get(
            "/api/bookings/my/next",
            as: NextBookingResponse.self
        )

        feed = await feedResult
        nextBooking = await nextResult?.booking
        isLoading = false
    }
}

struct HomeFeed: Decodable {
    let following: [DiscoverProvider]?
    let trending: [DiscoverProvider]?
    let nearby: [DiscoverProvider]?
    let topRated: [DiscoverProvider]?
}
