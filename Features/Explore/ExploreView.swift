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
    @State private var isLoadingMore = false
    @State private var gridView: GridTab = .providers
    @State private var apiCategories: [APICategory] = []
    @State private var showCategoryPicker = false
    @State private var pickerSelectedIds: Set<String> = []

    enum GridTab { case providers, salons }

    private static let preferredCategoryKey = "preferred_explore_category_ids"

    private var preferredCategoryIds: Set<String> {
        let saved = UserDefaults.standard.stringArray(forKey: Self.preferredCategoryKey) ?? []
        return Set(saved)
    }

    private var visibleCategories: [APICategory] {
        let prefs = preferredCategoryIds
        if prefs.isEmpty { return apiCategories }
        return apiCategories.filter { prefs.contains($0.id) }
    }

    private func savePreferredCategories(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: Self.preferredCategoryKey)
    }

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

    private let categoryDisplay: [String: (icon: String, sv: String, en: String)] = [
        "hair": ("💇", "Hår", "Hair"),
        "nails": ("💅", "Naglar", "Nails"),
        "lashes": ("👁️", "Fransar", "Lashes"),
        "skin": ("🧴", "Hud", "Skin"),
        "tattoo": ("🎨", "Tatuering", "Tattoo"),
    ]

    /// The active category stores the UUID from the API, not the slug
    private var activeCategorySlug: String? {
        guard let id = activeCategory else { return nil }
        return apiCategories.first(where: { $0.id == id })?.slug
    }

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

            // Category pills — uses UUIDs from API, filtered by preferences
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(visibleCategories, id: \.id) { cat in
                            let display = categoryDisplay[cat.slug]
                            let label = display.map { "\($0.icon) \(appState.isSv ? $0.sv : $0.en)" } ?? (appState.isSv ? cat.nameSv : (cat.nameEn ?? cat.nameSv))
                            Button {
                                let newCategory = activeCategory == cat.id ? nil : cat.id
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
                                    .background(activeCategory == cat.id ? BokviaTheme.accent : Color(.secondarySystemBackground))
                                    .foregroundStyle(activeCategory == cat.id ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .id(cat.id)
                        }
                        // Settings button at end of category row
                        Button {
                            if preferredCategoryIds.isEmpty {
                                pickerSelectedIds = Set(apiCategories.map(\.id))
                            } else {
                                pickerSelectedIds = preferredCategoryIds
                            }
                            showCategoryPicker = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(appState.isSv ? "Anpassa kategorier" : "Customize categories")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(
                    categories: apiCategories,
                    selectedIds: $pickerSelectedIds,
                    isSv: appState.isSv,
                    categoryDisplay: categoryDisplay,
                    onSave: {
                        let allIds = Set(apiCategories.map(\.id))
                        if pickerSelectedIds == allIds {
                            savePreferredCategories([])
                        } else {
                            savePreferredCategories(pickerSelectedIds)
                        }
                        if let active = activeCategory, !pickerSelectedIds.contains(active) {
                            activeCategory = nil
                            activeSubcategory = nil
                            Task { await loadProviders() }
                        }
                        showCategoryPicker = false
                    },
                    onReset: {
                        savePreferredCategories([])
                        showCategoryPicker = false
                    }
                )
                .presentationDetents([.medium])
            }

            // Subcategory pills — show when a category is selected, uses UUIDs
            if let catId = activeCategory,
               let cat = visibleCategories.first(where: { $0.id == catId }),
               !cat.subcategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(cat.subcategories, id: \.id) { sub in
                            Button {
                                activeSubcategory = activeSubcategory == sub.id ? nil : sub.id
                                Task { await loadProviders() }
                            } label: {
                                Text(appState.isSv ? sub.nameSv : (sub.nameEn ?? sub.nameSv))
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(activeSubcategory == sub.id ? BokviaTheme.accent.opacity(0.15) : Color(.tertiarySystemBackground))
                                    .foregroundStyle(activeSubcategory == sub.id ? BokviaTheme.accent : .secondary)
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

                        // 3-column grid with infinite scroll
                        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                        LazyVGrid(columns: gridItems, spacing: 8) {
                            if gridView == .providers {
                                ForEach(Array(providers.enumerated()), id: \.element.id) { index, p in
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
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .onAppear {
                                        // Load more when last item appears
                                        if p.id == providers.last?.id && hasMore && !isLoadingMore {
                                            Task { await loadMore() }
                                        }
                                    }
                                }
                            } else {
                                ForEach(salons) { s in
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
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .animation(.easeOut(duration: 0.3), value: providers.count)
                        .animation(.easeOut(duration: 0.3), value: salons.count)

                        // Loading indicator for infinite scroll
                        if gridView == .providers && isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle(appState.isSv ? "Utforska" : "Explore")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load categories from API so we get UUIDs
            await loadCategories()
            if !initialSearch.isEmpty { searchText = initialSearch }
            if let cat = initialCategory {
                // initialCategory may be a slug — resolve to UUID
                if let found = apiCategories.first(where: { $0.slug == cat }) {
                    activeCategory = found.id
                } else {
                    activeCategory = cat
                }
            }
            await loadProviders()
        }
        // Re-load when booking profile changes (family member switch)
        .onChange(of: appState.activeBookingProfile?.id) { _, _ in
            Task { await loadProviders() }
        }
    }

    /// Derive segment query params from active booking profile or current user
    private var segmentParams: String {
        // If a family member is selected, use their segment
        if let profile = appState.activeBookingProfile {
            let seg = profile.segment
            if seg != "UNSPECIFIED" {
                let g = profile.gender ?? ""
                return "&segment=\(seg)&gender=\(g)"
            }
            return ""
        }
        // Otherwise derive from the user's own gender + DOB
        guard let user = appState.currentUser else { return "" }
        let g = (user.gender ?? "").lowercased()
        let dob = user.dateOfBirth
        let seg = deriveUserSegment(gender: g, dateOfBirth: dob)
        if seg != "UNSPECIFIED" {
            return "&segment=\(seg)&gender=\(g)"
        }
        return ""
    }

    private func deriveUserSegment(gender: String, dateOfBirth: String?) -> String {
        let g = gender.lowercased()
        guard !g.isEmpty, g != "prefer-not", g != "prefer_not_to_say" else { return "UNSPECIFIED" }
        if g == "non-binary" { return "UNSPECIFIED" }
        let age = dateOfBirth.flatMap { calculateAgeFromString($0) }
        if g == "male" || g == "man" {
            if let a = age, a < 13 { return "BOY" }
            if let a = age, a >= 65 { return "SENIOR" }
            return "MAN"
        }
        if g == "female" || g == "woman" {
            if let a = age, a < 13 { return "GIRL" }
            if let a = age, a >= 65 { return "SENIOR" }
            return "WOMAN"
        }
        return "UNSPECIFIED"
    }

    private func calculateAgeFromString(_ dob: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dob) else { return nil }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year
    }

    private func loadProviders() async {
        isLoading = true
        errorMessage = nil
        page = 1
        let loc = LocationManager.shared
        var path = "/api/providers/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&sort=\(sortOption.rawValue)&page=1&pageSize=\(Config.defaultPageSize)"
        if let cat = activeCategory { path += "&categoryId=\(cat)" }
        if let sub = activeSubcategory { path += "&subcategoryId=\(sub)" }
        if let wm = activeWorkMode { path += "&workMode=\(wm)" }
        path += segmentParams

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: ProviderDiscoverWrapper.self)
            providers = result.data.items
            hasMore = result.data.hasMore
        } catch {
            providers = []
            errorMessage = appState.isSv ? "Kunde inte ladda. Försök igen." : "Failed to load. Try again."
        }
        // Load salons for grid — pass category filter so salons sync with selected category
        do {
            var salonPath = "/api/salons/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&radius=10"
            if let cat = activeCategory { salonPath += "&categoryId=\(cat)" }
            let salonResult = try await APIClient.shared.getNoAuth(
                salonPath,
                as: SalonDiscoverWrapper.self
            )
            salons = salonResult.data.items
        } catch { /* salons are optional for grid */ }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        page += 1
        let loc = LocationManager.shared
        var path = "/api/providers/discover?lat=\(loc.latitude)&lng=\(loc.longitude)&sort=\(sortOption.rawValue)&page=\(page)&pageSize=9"
        if let cat = activeCategory { path += "&categoryId=\(cat)" }
        if let sub = activeSubcategory { path += "&subcategoryId=\(sub)" }
        if let wm = activeWorkMode { path += "&workMode=\(wm)" }
        path += segmentParams

        do {
            let result = try await APIClient.shared.getNoAuth(path, as: ProviderDiscoverWrapper.self)
            providers.append(contentsOf: result.data.items)
            hasMore = result.data.hasMore
        } catch {
            page -= 1
            errorMessage = appState.isSv ? "Kunde inte ladda mer." : "Failed to load more."
        }
        isLoadingMore = false
    }

    private func search() async {
        guard !searchText.isEmpty else { await loadProviders(); return }
        isLoading = true
        errorMessage = nil
        let q = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        do {
            let result = try await APIClient.shared.getNoAuth("/api/providers/search?q=\(q)\(segmentParams)", as: ProviderDiscoverWrapper.self)
            providers = result.data.items
            hasMore = result.data.hasMore
        } catch {
            errorMessage = appState.isSv ? "Sökningen misslyckades." : "Search failed."
        }
        isLoading = false
    }

    private func loadCategories() async {
        let allowed = Set(["hair", "nails", "lashes", "skin", "tattoo"])
        do {
            let result = try await APIClient.shared.getNoAuth("/api/search/categories", as: CategoriesWrapper.self)
            apiCategories = result.data.filter { allowed.contains($0.slug) }
        } catch {
            // Fallback — empty categories, pills won't show but page still works
            apiCategories = []
        }
    }
}

// MARK: - API response wrappers
private struct ProviderDiscoverWrapper: Decodable {
    let data: PaginatedProviders
}

private struct SalonDiscoverWrapper: Decodable {
    let data: PaginatedSalons
}

private struct CategoriesWrapper: Decodable {
    let data: [APICategory]
}

struct APICategory: Decodable, Identifiable {
    let id: String
    let slug: String
    let nameSv: String
    let nameEn: String?
    let subcategories: [APISubcategory]
}

struct APISubcategory: Decodable, Identifiable {
    let id: String
    let slug: String
    let nameSv: String
    let nameEn: String?
}

// MARK: - Category picker sheet
struct CategoryPickerSheet: View {
    let categories: [APICategory]
    @Binding var selectedIds: Set<String>
    let isSv: Bool
    let categoryDisplay: [String: (icon: String, sv: String, en: String)]
    let onSave: () -> Void
    let onReset: () -> Void

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(isSv ? "Visa bara det du bryr dig om" : "Show only what you care about")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                VStack(spacing: 8) {
                    ForEach(categories, id: \.id) { cat in
                        let isSelected = selectedIds.contains(cat.id)
                        let display = categoryDisplay[cat.slug]
                        let label = display.map { "\($0.icon) \(isSv ? $0.sv : $0.en)" } ?? (isSv ? cat.nameSv : (cat.nameEn ?? cat.nameSv))

                        Button {
                            if isSelected && selectedIds.count > 1 {
                                selectedIds.remove(cat.id)
                            } else if !isSelected {
                                selectedIds.insert(cat.id)
                            }
                        } label: {
                            HStack {
                                Text(label)
                                    .font(.body.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(.primary)
                                Spacer()
                                ZStack {
                                    Circle()
                                        .stroke(isSelected ? BokviaTheme.accent : Color(.separator), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    if isSelected {
                                        Circle()
                                            .fill(BokviaTheme.accent)
                                            .frame(width: 24, height: 24)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? BokviaTheme.accent.opacity(0.08) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? BokviaTheme.accent : Color(.separator), lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onSave) {
                        Text(isSv ? "Spara" : "Save")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary)
                            .foregroundStyle(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: onReset) {
                        Text(isSv ? "Visa alla kategorier" : "Show all categories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationTitle(isSv ? "Välj kategorier" : "Choose categories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.secondary)
                    )
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)

            if rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if isSponsored {
                Text(isSv ? "Sponsrad" : "Sponsored")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(red: 0.57, green: 0.44, blue: 0.05))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color(red: 0.996, green: 0.953, blue: 0.788))
                    .clipShape(Capsule())
            }
        }
    }
}
