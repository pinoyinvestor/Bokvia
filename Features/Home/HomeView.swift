import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var feed: HomeFeed?
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var nextBooking: Booking?
    @State private var topSalons: [DiscoverSalon] = []
    @State private var topRatedProviders: [DiscoverProvider] = []

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
                // Search bar — top priority
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

                // Hero greeting
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.title.bold())
                        Text(appState.isSv ? "Boka behandlingar nära dig" : "Book treatments near you")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    avatarView
                }
                .padding(.horizontal)

                // Built by Christos Ferlachidis & Daniel Hedenberg

                // Next booking
                if let booking = nextBooking {
                    nextBookingCard(booking)
                }

                // Sections from feed
                if isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if let feed = feed {
                    // Following
                    if let following = feed.following, !following.isEmpty {
                        sectionHeader(appState.isSv ? "Följer" : "Following")
                        providerRow(following)
                    }

                    // SECTION 1: Topprankade — social proof, quality signal
                    let topRated = topRatedForDisplay
                    if !topRated.isEmpty {
                        sectionHeaderWithAction(
                            icon: "⭐",
                            title: appState.isSv ? "Topprankade" : "Top Rated",
                            destination: "explore?sort=top_rated"
                        )
                        topRatedRow(topRated)
                    }

                    // SECTION 2: Topp Behandlare nära dig — exclude those already in section 1
                    let filteredProviders = topRatedProviders.filter { p in
                        !topRated.contains(where: { $0.id == p.id })
                    }
                    if !filteredProviders.isEmpty {
                        sectionHeaderWithAction(
                            icon: "💇",
                            title: appState.isSv ? "Topp behandlare" : "Top Providers",
                            destination: "explore?sort=top_rated"
                        )
                        topProviderRow(filteredProviders)
                    }

                    // SECTION 3: Topp Salonger nära dig — salons by rating
                    if !topSalons.isEmpty {
                        sectionHeaderWithAction(
                            icon: "🏪",
                            title: appState.isSv ? "Topp salonger" : "Top Salons",
                            destination: "explore?tab=salons"
                        )
                        salonRow(topSalons)
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

    // Combine topRankedThisMonth from feed with topRatedProviders
    private var topRatedForDisplay: [DiscoverProvider] {
        if let topRated = feed?.topRated, !topRated.isEmpty { return topRated }
        if let trending = feed?.trending, !trending.isEmpty { return trending }
        return topRatedProviders
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

    private func sectionHeaderWithAction(icon: String, title: String, destination: String) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.callout)
                Text(title)
                    .font(.headline)
            }
            Spacer()
            NavigationLink {
                ExploreView()
            } label: {
                Text(appState.isSv ? "Visa alla" : "See all")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BokviaTheme.accent)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Following Row

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

    // MARK: - Section 1: Top Rated Row

    private func topRatedRow(_ providers: [DiscoverProvider]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(providers.prefix(10))) { provider in
                    NavigationLink {
                        ProviderProfileView(slug: provider.slug)
                    } label: {
                        VStack(spacing: 6) {
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

                            if provider.ratingAvg > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    Text(String(format: "%.1f", provider.ratingAvg))
                                        .font(.caption2.bold())
                                    if provider.reviewCount > 0 {
                                        Text("(\(provider.reviewCount))")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }

                            if let price = provider.startingPrice, price > 0 {
                                Text("\(appState.isSv ? "Från" : "From") \(Int(price)) kr")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 100)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Section 2: Top Provider Row (with city + work modes)

    private func topProviderRow(_ providers: [DiscoverProvider]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(providers.prefix(10))) { provider in
                    NavigationLink {
                        ProviderProfileView(slug: provider.slug)
                    } label: {
                        VStack(spacing: 6) {
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

                            if provider.ratingAvg > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    Text(String(format: "%.1f", provider.ratingAvg))
                                        .font(.caption2)
                                }
                            }

                            if let city = provider.city {
                                Text(city)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }

                            if let price = provider.startingPrice, price > 0 {
                                Text("\(appState.isSv ? "Från" : "From") \(Int(price)) kr")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            if let modes = provider.workModes, !modes.isEmpty {
                                HStack(spacing: 3) {
                                    ForEach(modes.prefix(2), id: \.self) { mode in
                                        Text(workModeLabel(mode))
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .frame(width: 100)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    private func workModeLabel(_ mode: String) -> String {
        switch mode {
        case "SALON": return appState.isSv ? "Salong" : "Salon"
        case "MOBILE": return appState.isSv ? "Mobil" : "Mobile"
        case "HOME": return appState.isSv ? "Hemma" : "Home"
        default: return mode
        }
    }

    // MARK: - Salon Row

    private func salonRow(_ salons: [DiscoverSalon]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(salons) { salon in
                    NavigationLink {
                        SalonProfileView(slug: salon.slug)
                    } label: {
                        compactSalonCard(salon)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    private func compactSalonCard(_ salon: DiscoverSalon) -> some View {
        VStack(spacing: 6) {
            if let logoUrl = salon.logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(BokviaTheme.gray200)
                        .overlay(
                            Text(String(salon.name.prefix(1)))
                                .font(.title3.bold())
                                .foregroundStyle(.secondary)
                        )
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            } else {
                Circle().fill(BokviaTheme.gray200)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(String(salon.name.prefix(1)))
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    )
            }

            Text(salon.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if salon.ratingAvg > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", salon.ratingAvg))
                        .font(.caption2)
                }
            }

            if let count = salon.providerCount, count > 0 {
                Text("\(count) \(appState.isSv ? "behandlare" : "providers")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let city = salon.city {
                Text(city)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 100)
    }

    /// Derive segment query params from active booking profile or current user
    private var segmentParams: String {
        if let profile = appState.activeBookingProfile {
            let seg = profile.segment
            if seg != "UNSPECIFIED" {
                let g = profile.gender ?? ""
                return "&segment=\(seg)&gender=\(g)"
            }
            return ""
        }
        guard let user = appState.currentUser else { return "" }
        let g = (user.gender ?? "").lowercased()
        guard !g.isEmpty, g != "prefer-not", g != "prefer_not_to_say", g != "non-binary" else { return "" }
        let dob = user.dateOfBirth
        let age: Int? = dob.flatMap {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            guard let date = fmt.date(from: $0) else { return nil }
            return Calendar.current.dateComponents([.year], from: date, to: Date()).year
        }
        let seg: String
        if g == "male" || g == "man" {
            if let a = age, a < 13 { seg = "BOY" }
            else if let a = age, a >= 65 { seg = "SENIOR" }
            else { seg = "MAN" }
        } else if g == "female" || g == "woman" {
            if let a = age, a < 13 { seg = "GIRL" }
            else if let a = age, a >= 65 { seg = "SENIOR" }
            else { seg = "WOMAN" }
        } else { return "" }
        return "&segment=\(seg)&gender=\(g)"
    }

    private func loadData() async {
        let loc = LocationManager.shared
        let lat = loc.hasLocation ? loc.latitude : Config.defaultLatitude
        let lng = loc.hasLocation ? loc.longitude : Config.defaultLongitude
        let sp = segmentParams

        async let feedResult: HomeFeed? = try? await APIClient.shared.get(
            "/api/feed/home?lat=\(lat)&lng=\(lng)&radius=\(Config.feedRadius)\(sp)",
            as: HomeFeed.self
        )
        async let nextResult: NextBookingResponse? = try? await APIClient.shared.get(
            "/api/bookings/my/next",
            as: NextBookingResponse.self
        )
        async let salonsResult: PaginatedSalons? = try? await APIClient.shared.getNoAuth(
            "/api/salons/discover?lat=\(lat)&lng=\(lng)&distance=50",
            as: PaginatedSalons.self
        )
        async let topRatedResult: PaginatedProviders? = try? await APIClient.shared.getNoAuth(
            "/api/providers/discover?lat=\(lat)&lng=\(lng)&radius=50&sort=top_rated&pageSize=10\(sp)",
            as: PaginatedProviders.self
        )

        feed = await feedResult
        nextBooking = await nextResult?.booking
        topSalons = Array((await salonsResult)?.items.prefix(10) ?? [])
        topRatedProviders = (await topRatedResult)?.items ?? []
        isLoading = false
    }
}

struct HomeFeed: Decodable {
    let following: [DiscoverProvider]?
    let trending: [DiscoverProvider]?
    let nearby: [DiscoverProvider]?
    let topRated: [DiscoverProvider]?
}
