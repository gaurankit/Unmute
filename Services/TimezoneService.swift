import Foundation

struct TimezoneCity: Identifiable, Hashable {
    let id: String // timezone identifier (e.g., "Asia/Kolkata")
    let city: String
    let country: String
    let abbreviation: String
    let utcOffset: String

    var displayName: String {
        "\(city), \(country)"
    }

    var fullDisplay: String {
        "\(city), \(country) (\(abbreviation), \(utcOffset))"
    }
}

final class TimezoneService {
    static let shared = TimezoneService()

    private let cities: [TimezoneCity]

    private init() {
        // Build city list from all known timezone identifiers
        var result: [TimezoneCity] = []
        let now = Date()

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            guard let tz = TimeZone(identifier: identifier) else { continue }

            // Parse city name from identifier (e.g., "Asia/Kolkata" -> "Kolkata")
            let parts = identifier.split(separator: "/")
            guard parts.count >= 2 else { continue }

            let cityName = String(parts.last!)
                .replacingOccurrences(of: "_", with: " ")

            let region = String(parts.first!)

            // Map region to a more user-friendly country/region name
            let country = Self.regionToCountry(region: region, city: cityName)

            let abbreviation = tz.abbreviation(for: now) ?? ""
            let seconds = tz.secondsFromGMT(for: now)
            let hours = seconds / 3600
            let minutes = abs(seconds % 3600) / 60
            let sign = hours >= 0 ? "+" : ""
            let utcOffset = minutes == 0
                ? "UTC\(sign)\(hours)"
                : "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"

            result.append(TimezoneCity(
                id: identifier,
                city: cityName,
                country: country,
                abbreviation: abbreviation,
                utcOffset: utcOffset
            ))
        }

        self.cities = result.sorted { $0.city < $1.city }
    }

    func search(query: String) -> [TimezoneCity] {
        if query.isEmpty {
            return Array(cities.prefix(20))
        }

        let lowered = query.lowercased()
        return cities.filter { city in
            city.city.lowercased().contains(lowered) ||
            city.country.lowercased().contains(lowered) ||
            city.abbreviation.lowercased().contains(lowered)
        }
    }

    func city(for identifier: String) -> TimezoneCity? {
        cities.first { $0.id == identifier }
    }

    // MARK: - Helpers

    private static func regionToCountry(region: String, city: String) -> String {
        // Simplified mapping for common regions
        let cityCountryMap: [String: String] = [
            "Kolkata": "India",
            "Mumbai": "India",
            "New Delhi": "India",
            "Chennai": "India",
            "New York": "USA",
            "Los Angeles": "USA",
            "Chicago": "USA",
            "Denver": "USA",
            "Phoenix": "USA",
            "Anchorage": "USA",
            "Honolulu": "USA",
            "London": "UK",
            "Paris": "France",
            "Berlin": "Germany",
            "Tokyo": "Japan",
            "Shanghai": "China",
            "Hong Kong": "China",
            "Sydney": "Australia",
            "Melbourne": "Australia",
            "Dubai": "UAE",
            "Singapore": "Singapore",
            "Seoul": "South Korea",
            "Toronto": "Canada",
            "Vancouver": "Canada",
            "Moscow": "Russia",
            "Sao Paulo": "Brazil",
            "Cairo": "Egypt",
            "Istanbul": "Turkey",
            "Bangkok": "Thailand",
            "Jakarta": "Indonesia",
            "Karachi": "Pakistan",
            "Lagos": "Nigeria",
            "Nairobi": "Kenya",
            "Johannesburg": "South Africa",
            "Auckland": "New Zealand",
            "Lima": "Peru",
            "Bogota": "Colombia",
            "Mexico City": "Mexico",
        ]

        if let country = cityCountryMap[city] {
            return country
        }

        // Fallback to region name
        let regionMap: [String: String] = [
            "America": "Americas",
            "Europe": "Europe",
            "Asia": "Asia",
            "Africa": "Africa",
            "Australia": "Australia",
            "Pacific": "Pacific",
            "Atlantic": "Atlantic",
            "Indian": "Indian Ocean",
            "Arctic": "Arctic",
            "Antarctica": "Antarctica",
        ]

        return regionMap[region] ?? region
    }
}
