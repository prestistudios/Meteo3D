import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var place = Place(
        id: 6077243,
        name: "Montréal",
        latitude: 45.50884,
        longitude: -73.58781,
        country: "Canada",
        admin1: "Québec"
    )
    @Published var forecast: ForecastResponse?
    @Published var searchResults: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = OpenMeteoService()
    private var searchTask: Task<Void, Never>?

    var days: [DayForecast] {
        guard let daily = forecast?.daily else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return daily.time.indices.compactMap { index in
            guard let date = formatter.date(from: daily.time[index]),
                  daily.weatherCode.indices.contains(index),
                  daily.temperature2mMax.indices.contains(index),
                  daily.temperature2mMin.indices.contains(index),
                  daily.precipitationProbabilityMax.indices.contains(index)
            else { return nil }
            return DayForecast(
                id: daily.time[index],
                date: date,
                code: daily.weatherCode[index],
                high: daily.temperature2mMax[index],
                low: daily.temperature2mMin[index],
                rainChance: daily.precipitationProbabilityMax[index]
            )
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            forecast = try await service.forecast(for: place)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func search(_ query: String) {
        searchTask?.cancel()
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            do {
                searchResults = try await service.searchPlaces(named: query)
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }

    func select(_ newPlace: Place) async {
        place = newPlace
        searchResults = []
        await load()
    }
}
