import SwiftUI
import MapKit

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var providers: [DiscoverProvider] = []
    @State private var sections: DiscoverSections?
    @State private var isLoading = true
    @State private var viewMode: ViewMode = .list
    @State private var sortOption: SortOption = .recommended
    @State private var activeCategory: String?
    @State private var activeSubcategory: String?
    @State private var searchText = ""
    @State private var page = 1
    @State private var hasMore = true
    @State private var errorMessage: String?
    @State private var activeWorkMode: String? = nil
    @State private var salons: [DiscoverSalon] = []
    @State private var gridView: GridTab = .providers

    enum GridTab { case providers, salons }

    var initialSearch: String = ""
    var initialCategory: String? = nil

    enum ViewMode { case list, map }
    enum SortOption: String, CaseIterable {
        case recommended, top_rated, most_booked, nearest, lowest_price
        var label: String {
            switch self {
            case .recommended: return "Rekommenderat"
            case .top_rated: return "Högst betyg"
            case .most_booked: return "Mest bokade"
            case .nearest: return "Närmast"
            case .lowest_price: return "Lägst pris"
            }
        }
    }

    private let categoryOptions = [
        ("hair", "💇 Hår"), ("nails", "💅 Naglar"), ("lashes", "👁️ Fransar"),
        ("skin", "🧴 Hud"), ("tattoo", "🎨 Tatuering"),
    ]

    private let subcategoryMap: [String: [(slug: String, label: String)]] = [
        "hair": [("haircut", "Klippning"), ("coloring", "Färgning"), ("styling", "Styling"), ("extensions", "Extensions")],
        "nails": [("manicure", "Manikyr"), ("pedicure", "Pedikyr"), ("gel", "Gel"), ("acrylics", "Akryl")],
        "lashes": [("extensions_l", "Extensions"), ("lift", "Lash lift"), ("tint", "Färgning")],
        "skin": [("facial", "Ansiktsbehandling"), ("peeling", "Peeling"), ("laser", "Laser")],
        "tattoo": [("tattoo_new", "Ny tatuering"), ("cover_up", "Cover-up"), ("removal", "Borttagning")],
    ]

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(appState.isSv ? "Sök..." : "Search...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await search() } }
                if !searchText.isEmpty {
                    Button { searchText = ""; Task { await loadProviders() } } label: {
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

            // Category pills
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categoryOptions, id: \.0) { slug, label in
                            Button {
                                let newCategory = activeCategory == slug ? nil : slug
                                activeCategory = newCategory
                                activeSubcategory = nil
                                if let selected = newCategory {
                                    withAnimation {
                                        proxy.scrollTo(selected, anchor: .leading)
                                    }
                                }
                                Task { await loadProviders() }
                            } label: {
                                Text(label)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(activeCategory == slug ? BokviaTheme.accent : Color(.secondarySystemBackground))
                                    .foregroundStyle(activeCategory == slug ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .id(slug)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            // Subcategory pills — show when a category is selected
            if let cat = activeCategory, let subs = subcategoryMap[cat] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(subs, id: \.slug) { sub in
                            Button {
                                activeSubcategory = activeSubcategory == sub.slug ? nil : sub.slug
                                Task { await loadProviders() }
                            } label: {
                                Text(sub.label)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(activeSubcategory == sub.slug ? BokviaTheme.accent.opacity(0.15) : Color(.tertiarySystemBackground))
                                    .foregroundStyle(activeSubcategory == sub.slug ? BokviaTheme.accent : .secondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Work mode pills — "Var?"
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text(appState.isSv ? "Var?" : "Where?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach([
                        ("AT_SALON", "🏪", "Salong", "Salon"),
                        ("AT_PROVIDER", "🏠", "Mottagning", "Studio"),
                        ("HOME_VISIT", "🚗", "Hembesök", "Home visit"),
                    ], id: \.0) { mode, icon, sv, en in
                        Button {
                            activeWorkMode = activeWorkMode == mode ? nil : mode
                            Task { await loadProviders() }
                        } label: {
                            HStack(spacing: 4) {
                                Text(icon)
                                Text(appState.isSv ? sv : en)
                            }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(activeWorkMode == mode ? BokviaTheme.accent : Color(.secondarySystemBackground))
                            .foregroundStyle(activeWorkMode == mode ? .white : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(activeWorkMode == mode ? Color.clear : Color(.separator), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 4)

            // Sort + view toggle
            HStack(spacing: 10) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                            Task { await loadProviders() }
                        } label: {
                            HStack {
                                Text(option.label)
                                if sortOption == option { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.label)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewMode = viewMode == .list ? .map : .list
                } label: {
                    Image(systemName: viewMode == .list ? "map" : "list.bullet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(viewMode == .list
                    ? (appState.isSv ? "Visa karta" : "Show map")
                    : (appState.isSv ? "Visa lista" : "Show list"))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            // Content
            if viewMode == .map {
                MapExploreView(providers: providers, locale: appState.language)
            } else if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Grid toggle: Behandlare | Salonger
                        HStack(spacing: 8) {
                            Button {
                                gridView = .providers
                            } label: {
                                Text(appState.isSv ? "Behandlare" : "Providers")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(gridView == .providers ? Color.primary : Color(.secondarySystemBackground))
                                    .foregroundStyle(gridView == .providers ? Color(.systemBackground) : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(gridView == .providers ? Color.clear : Color(.separator), lineWidth: 1.5))
                            }
                            Button {
                                gridView = .salons
                            } label: {
                                Text(appState.isSv ? "Salonger" : "Salons")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(gridView == .salons ? Color.primary : Color(.secondarySystemBackground))
                                    .foregroundStyle(gridView == .salons ? Color(.systemBackground) : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(gridView == .salons ? Color.clear : Color(.separator), lineWidth: 1.5))
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 3-column grid
                        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                        LazyVGrid(columns: gridItems, spacing: 16) {
                            if gridView == .providers {
                                ForEach(providers.prefix(12)) { p in
                                    NavigationLink {
                                        ProviderProfileView(slug: p.slug)
                                    } label: {
                                        ExploreGridCell(
                                            imageUrl: p.avatarUrl,
                                            name: p.displayName,
                                            rating: p.ratingAvg,
                                            isSponsored: p.isSponsored,
                                            isSv: appState.isSv
                                        )
                                    }
                                    .foregroundStyle(.primary)
                                }
                            } else {
                                ForEach(salons.prefix(12)) { s in
                                    NavigationLink {
                                        SalonProfileView(slug: s.slug)
                                    } label: {
                                        ExploreGridCell(
                                            imageUrl: s.logoUrl,
                                            name: s.name,
                                            rating: s.ratingAvg,
                                            isSponsored: false,
                                            isSv: appState.isSv
                                        )
                                    }
                                    .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Provider list
                        LazyVStack(spacing: 8) {
                            ForEach(providers) { provider in
                                NavigationLink {
                                    ProviderProfileView(slug: provider.slug)
                                } label: {
                                    ProviderCard(provider: provider, locale: appState.language)
                                }
                                .foregroundStyle(.primary)
                                .onAppear {
                                    if provider.id == providers.last?.id && hasMore {
                                        Task { await loadMore() }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(appState.isSv ? "Utforska" : "Explore")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !initialSearch.isEmpty { searchText = initialSearch }
            if let cat = initialCategory { activeCategory = cat }
            await loadProviders()
        }
    }

    private func loadProviders() async {
        isLoading = true
        errorMessage = nil
        page = 1
        let loc = LocationManager.shared
        var path = "/api/providers/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&sort=\(sortOption.rawValue)&page=1&pageSize=\(Config.defaultPageSize)"
        if let cat = activeCategory { path += "&category=\(cat)" }
        if let sub = activeSubcategory { path += "&subcategory=\(sub)" }
        if let wm = activeWorkMode { path += "&workMode=\(wm)" }

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: ProviderDiscoverWrapper.self)
            providers = result.data.items
            hasMore = result.data.hasMore
        } catch {
            providers = []
            errorMessage = appState.isSv ? "Kunde inte ladda. Försök igen." : "Failed to load. Try again."
        }
        // Load salons for grid
        do {
            let salonResult = try await APIClient.shared.getNoAuth(
                "/api/salons/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&radius=10",
                as: SalonDiscoverWrapper.self
            )
            salons = salonResult.data.items
        } catch { /* salons are optional for grid */ }
        isLoading = false
    }

    private func loadMore() async {
        page += 1
        let loc = LocationManager.shared
        var path = "/api/providers/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&sort=\(sortOption.rawValue)&page=\(page)&pageSize=\(Config.defaultPageSize)"
        if let cat = activeCategory { path += "&category=\(cat)" }
        if let sub = activeSubcategory { path += "&subcategory=\(sub)" }
        if let wm = activeWorkMode { path += "&workMode=\(wm)" }

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: ProviderDiscoverWrapper.self)
            providers.append(contentsOf: result.data.items)
            hasMore = result.data.hasMore
        } catch {
            page -= 1
            errorMessage = appState.isSv ? "Kunde inte ladda mer." : "Failed to load more."
        }
    }

    private func search() async {
        guard !searchText.isEmpty else { await loadProviders(); return }
        isLoading = true
        errorMessage = nil
        let q = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        do {
            let result = try await APIClient.shared.getNoAuth("/api/providers/search?q=\(q)", as: ProviderDiscoverWrapper.self)
            providers = result.data.items
            hasMore = result.data.hasMore
        } catch {
            errorMessage = appState.isSv ? "Sökningen misslyckades." : "Search failed."
        }
        isLoading = false
    }
}

// MARK: - API response wrappers
private struct ProviderDiscoverWrapper: Decodable {
    let data: PaginatedProviders
}

private struct SalonDiscoverWrapper: Decodable {
    let data: PaginatedSalons
}

// MARK: - Grid cell for Behandlare/Salonger grid
struct ExploreGridCell: View {
    let imageUrl: String?
    let name: String
    let rating: Double
    let isSponsored: Bool
    let isSv: Bool

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    )
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)

            if rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", rating))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if isSponsored {
                Text(isSv ? "Sponsrad" : "Sponsored")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(red: 0.57, green: 0.44, blue: 0.05))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.996, green: 0.953, blue: 0.788))
                    .clipShape(Capsule())
            }
        }
    }
}
