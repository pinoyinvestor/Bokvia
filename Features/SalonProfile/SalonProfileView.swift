import SwiftUI
import MapKit

struct SalonProfileView: View {
    let slug: String
    @Environment(AppState.self) private var appState
    @State private var salon: SalonDetail?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let salon = salon {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 12) {
                            AsyncImage(url: URL(string: salon.logoUrl ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(BokviaTheme.gray200)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text(salon.name)
                                .font(.title3.bold())

                            if let city = salon.city {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                    Text(city)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            // Built by Christos Ferlachidis & Daniel Hedenberg

                            HStack(spacing: 16) {
                                if salon.reviewCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.orange)
                                        Text(String(format: "%.1f", salon.ratingAvg))
                                            .fontWeight(.semibold)
                                        Text("(\(salon.reviewCount))")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }

                                if let count = salon.providerCount {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.2")
                                        Text("\(count) \(appState.isSv ? "frisörer" : "providers")")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Description
                        if let desc = salon.description, !desc.isEmpty {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        // Map
                        if let lat = salon.latitude, let lng = salon.longitude {
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            ))) {
                                Marker(salon.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)

                            if let address = salon.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                        }

                        // Team
                        if let providers = salon.providers, !providers.isEmpty {
                            Text(appState.isSv ? "Vårt team" : "Our team")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            LazyVStack(spacing: 8) {
                                ForEach(providers) { provider in
                                    NavigationLink {
                                        ProviderProfileView(slug: provider.slug)
                                    } label: {
                                        ProviderCard(provider: provider, locale: appState.language)
                                    }
                                    .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSalon() }
    }

    private func loadSalon() async {
        salon = try? await APIClient.shared.getNoAuth("/api/salons/slug/\(slug)", as: SalonDetail.self)
        isLoading = false
    }
}
