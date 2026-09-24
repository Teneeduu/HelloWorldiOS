import Foundation

struct Quote: Identifiable, Decodable, Equatable {
    let text: String
    let source: String

    var id: String { text }
}

/// The app and the widget each carry their own copy of quotes.json — a free
/// developer account cannot create the App Group they would need to share one.
enum BundledQuotes {
    static func load(from bundle: Bundle = .main) -> [Quote] {
        guard let url = bundle.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data)
        else { return [] }
        return decoded
    }

    /// Stable for a given calendar day, so the widget and the app agree.
    static func ofTheDay(_ quotes: [Quote], on date: Date = Date()) -> Quote? {
        guard !quotes.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return quotes[day % quotes.count]
    }
}
