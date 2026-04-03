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
    @State private var homeVisitOnly = false

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

            // Sort + view toggle + home visit filter
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

                Button {
                    homeVisitOnly.toggle()
                    Task { await loadProviders() }
                } label: {
                    Text(appState.isSv ? "\u{1F697} Hembes\u{00F6}k" : "\u{1F697} Home visit")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(homeVisitOnly ? BokviaTheme.accent : Color(.tertiarySystemBackground))
                        .foregroundStyle(homeVisitOnly ? .white : .secondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(homeVisitOnly ? Color.clear : Color(.separator), lineWidth: 1)
                        )
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
        if homeVisitOnly { path += "&workMode=HOME_VISIT" }

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: PaginatedProviders.self)
            providers = result.items
            hasMore = result.hasMore
        } catch {
            providers = []
            errorMessage = appState.isSv ? "Kunde inte ladda. Försök igen." : "Failed to load. Try again."
        }
        isLoading = false
    }

    private func loadMore() async {
        page += 1
        let loc = LocationManager.shared
        var path = "/api/providers/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&sort=\(sortOption.rawValue)&page=\(page)&pageSize=\(Config.defaultPageSize)"
        if let cat = activeCategory { path += "&category=\(cat)" }
        if let sub = activeSubcategory { path += "&subcategory=\(sub)" }
        if homeVisitOnly { path += "&workMode=HOME_VISIT" }

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: PaginatedProviders.self)
            providers.append(contentsOf: result.items)
            hasMore = result.hasMore
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
            let result = try await APIClient.shared.getNoAuth("/api/providers/search?q=\(q)", as: PaginatedProviders.self)
            providers = result.items
            hasMore = result.hasMore
        } catch {
            errorMessage = appState.isSv ? "Sökningen misslyckades." : "Search failed."
        }
        isLoading = false
    }
}
