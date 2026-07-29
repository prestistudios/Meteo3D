import SwiftUI

struct WeatherView: View {
    @StateObject private var model = WeatherViewModel()
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    currentCard
                    detailGrid
                    forecastStrip
                    attribution
                }
                .padding()
            }
            .refreshable { await model.load() }
        }
        .preferredColorScheme(.dark)
        .task { await model.load() }
        .sheet(isPresented: $showingSearch) {
            PlaceSearchView(model: model, isPresented: $showingSearch)
        }
        .alert("Météo indisponible", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Réessayer") { Task { await model.load() } }
            Button("Fermer", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var current: CurrentWeather? { model.forecast?.current }
    private var kind: WeatherKind { WeatherKind(code: current?.weatherCode ?? 1) }

    private var gradientColors: [Color] {
        guard current?.isDay != 0 else {
            return [
                Color(red: 0.08, green: 0.04, blue: 0.24),
                Color(red: 0.19, green: 0.10, blue: 0.46),
                Color(red: 0.04, green: 0.22, blue: 0.42)
            ]
        }
        switch kind {
        case .clear, .partlyCloudy:
            return [
                Color(red: 0.96, green: 0.26, blue: 0.08),
                Color(red: 0.96, green: 0.48, blue: 0.18),
                Color(red: 0.43, green: 0.18, blue: 0.66)
            ]
        default:
            return [
                Color(red: 0.10, green: 0.22, blue: 0.72),
                Color(red: 0.34, green: 0.16, blue: 0.68),
                Color(red: 0.02, green: 0.48, blue: 0.56)
            ]
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.place.name)
                    .font(.title2.bold())
                Text(model.place.subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3.bold())
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Rechercher une ville")
        }
    }

    private var currentCard: some View {
        VStack(spacing: 0) {
            WeatherSceneView(kind: kind, isDay: current?.isDay != 0)
                .frame(height: 300)
                .overlay(alignment: .bottomTrailing) {
                    Label("Touchez pour explorer", systemImage: "rotate.3d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(10)
                }

            HStack(alignment: .lastTextBaseline) {
                Text(current.map { "\(Int($0.temperature2m.rounded()))°" } ?? "—")
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: kind.symbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.title)
                    Text(kind.title)
                        .font(.headline)
                    if let current {
                        Text("Ressenti \(Int(current.apparentTemperature.rounded()))°")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14))
        }
    }

    private var detailGrid: some View {
        HStack(spacing: 12) {
            metric("Humidité", value: current.map { "\($0.relativeHumidity2m) %" } ?? "—", icon: "humidity.fill")
            metric("Vent", value: current.map { "\(Int($0.windSpeed10m.rounded())) km/h" } ?? "—", icon: "wind")
            metric("Pluie", value: current.map { String(format: "%.1f mm", $0.precipitation) } ?? "—", icon: "drop.fill")
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.30, green: 0.94, blue: 0.78))
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var forecastStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7 prochains jours")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.days) { day in
                        VStack(spacing: 8) {
                            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption.bold())
                            Image(systemName: WeatherKind(code: day.code).symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title2)
                            Text("\(Int(day.high.rounded()))°")
                                .font(.headline)
                            Text("\(Int(day.low.rounded()))°")
                                .foregroundStyle(.secondary)
                            Label("\(day.rainChance)%", systemImage: "drop.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0.30, green: 0.94, blue: 0.78))
                        }
                        .frame(width: 72)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }

    private var attribution: some View {
        Link(destination: URL(string: "https://open-meteo.com/")!) {
            Text("Données météo : Open‑Meteo · CC BY 4.0")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }
}

private struct PlaceSearchView: View {
    @ObservedObject var model: WeatherViewModel
    @Binding var isPresented: Bool
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(model.searchResults) { place in
                Button {
                    Task {
                        await model.select(place)
                        isPresented = false
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(place.name).font(.headline)
                        Text(place.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if model.searchResults.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty ? "Rechercher une ville" : "Aucun résultat",
                        systemImage: query.isEmpty ? "globe.americas.fill" : "magnifyingglass",
                        description: Text(query.isEmpty ? "Saisissez au moins deux caractères." : "Essayez une autre orthographe.")
                    )
                }
            }
            .navigationTitle("Changer de ville")
            .searchable(text: $query, prompt: "Montréal, Paris, Tokyo…")
            .onChange(of: query) { _, value in model.search(value) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { isPresented = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
