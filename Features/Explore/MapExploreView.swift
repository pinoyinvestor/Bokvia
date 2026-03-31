import SwiftUI
import MapKit

struct MapExploreView: View {
    let providers: [DiscoverProvider]
    let locale: String

    @State private var selectedProvider: DiscoverProvider?
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: $selectedProvider) {
                ForEach(providers.filter { $0.latitude != nil && $0.longitude != nil }) { provider in
                    Annotation(provider.displayName, coordinate: CLLocationCoordinate2D(
                        latitude: provider.latitude!,
                        longitude: provider.longitude!
                    )) {
                        providerPin(provider)
                    }
                    .tag(provider)
                }

                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                    .accessibilityLabel("Center on my location")
                MapCompass()
                    .accessibilityLabel("Map compass")
            }

            if let provider = selectedProvider {
                NavigationLink {
                    ProviderProfileView(slug: provider.slug)
                } label: {
                    ProviderCard(provider: provider, locale: locale)
                        .padding()
                        .shadow(radius: 8)
                }
                .foregroundStyle(.primary)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedProvider?.id)
    }

    private func providerPin(_ provider: DiscoverProvider) -> some View {
        VStack(spacing: 0) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.accent)
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(provider.isVerified ? BokviaTheme.accent : .white, lineWidth: 2))
            .shadow(radius: 2)

            Image(systemName: "triangle.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
    }
}
