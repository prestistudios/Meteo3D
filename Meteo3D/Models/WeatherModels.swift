import Foundation

struct Place: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?

    var subtitle: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct GeocodingResponse: Decodable {
    let results: [Place]?
}

struct ForecastResponse: Decodable {
    let current: CurrentWeather
    let daily: DailyWeather
}

struct CurrentWeather: Decodable {
    let temperature2m: Double
    let apparentTemperature: Double
    let relativeHumidity2m: Int
    let precipitation: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case isDay = "is_day"
    }
}

struct DailyWeather: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

struct DayForecast: Identifiable {
    let id: String
    let date: Date
    let code: Int
    let high: Double
    let low: Double
    let rainChance: Int
}

enum WeatherKind {
    case clear, partlyCloudy, cloudy, rain, storm, snow, fog

    init(code: Int) {
        switch code {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51...67, 80...82: self = .rain
        case 71...77, 85, 86: self = .snow
        case 95...99: self = .storm
        default: self = .cloudy
        }
    }

    var title: String {
        switch self {
        case .clear: "Dégagé"
        case .partlyCloudy: "Partiellement nuageux"
        case .cloudy: "Nuageux"
        case .rain: "Pluie"
        case .storm: "Orage"
        case .snow: "Neige"
        case .fog: "Brouillard"
        }
    }

    var symbol: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "cloud.snow.fill"
        case .fog: "cloud.fog.fill"
        }
    }
}
