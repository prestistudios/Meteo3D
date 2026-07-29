import Foundation

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Impossible de créer la requête."
        case .invalidResponse: "Le service météo a retourné une réponse inattendue."
        }
    }
}

struct OpenMeteoService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        decoder = JSONDecoder()
    }

    func searchPlaces(named query: String) async throws -> [Place] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            .init(name: "name", value: query),
            .init(name: "count", value: "8"),
            .init(name: "language", value: "fr"),
            .init(name: "format", value: "json")
        ]
        guard let url = components?.url else { throw WeatherServiceError.invalidURL }
        let response: GeocodingResponse = try await request(url)
        return response.results ?? []
    }

    func forecast(for place: Place) async throws -> ForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            .init(name: "latitude", value: String(place.latitude)),
            .init(name: "longitude", value: String(place.longitude)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m"),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "7")
        ]
        guard let url = components?.url else { throw WeatherServiceError.invalidURL }
        return try await request(url)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw WeatherServiceError.invalidResponse
        }
        return try decoder.decode(T.self, from: data)
    }
}
