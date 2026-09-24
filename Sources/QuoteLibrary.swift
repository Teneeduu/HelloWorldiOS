import Foundation

/// Quotes ship inside the app, and the user can add their own by dropping a
/// `Quotes.txt` into the app's folder — one per line, `句子 —— 出处`.
final class QuoteLibrary: ObservableObject {
    @Published private(set) var quotes: [Quote] = []
    @Published private(set) var current: Quote?

    private(set) var customCount = 0

    var customFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Quotes.txt")
    }

    init() {
        reload()
    }

    func reload() {
        let custom = loadCustom()
        customCount = custom.count
        quotes = BundledQuotes.load() + custom
        current = quoteOfTheDay()
    }

    func shuffle() {
        guard quotes.count > 1 else {
            current = quotes.first
            return
        }
        var pick = current
        while pick == current {
            pick = quotes.randomElement()
        }
        current = pick
    }

    func random() -> Quote? {
        quotes.randomElement()
    }

    func quoteOfTheDay() -> Quote? {
        BundledQuotes.ofTheDay(quotes)
    }

    private func loadCustom() -> [Quote] {
        guard let raw = try? String(contentsOf: customFileURL, encoding: .utf8) else { return [] }
        return raw
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                for separator in ["——", "--", "—"] {
                    if let range = trimmed.range(of: separator, options: .backwards) {
                        let text = trimmed[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
                        let source = trimmed[range.upperBound...].trimmingCharacters(in: .whitespaces)
                        if !text.isEmpty {
                            return Quote(text: text, source: source)
                        }
                    }
                }
                return Quote(text: trimmed, source: "")
            }
    }
}
