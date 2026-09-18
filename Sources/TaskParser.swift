import Foundation

struct ParsedTask: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var minutes: Int
}

/// One task per line, duration optional at the end of the line — the same
/// contract jo-app uses offline, so the two stay muscle-memory compatible.
enum TaskParser {
    static let defaultMinutes = 30

    private static let bullet = try! NSRegularExpression(
        pattern: "^\s*(?:[-*•·]|\d+[.、)）])\s*"
    )

    // Longer units first so "min" never wins over "mins". Bare "m" is left
    // out on purpose: "跑步 5000m" is metres, not minutes.
    private static let duration = try! NSRegularExpression(
        pattern: "[（(\[]?\s*(\d+(?:\.\d+)?)\s*(个小时|個小時|小时|小時|hrs|hr|h|分钟|分鐘|分|mins|min)\s*[)）\]]?\s*$",
        options: [.caseInsensitive]
    )

    private static let hourUnits: Set<String> = ["个小时", "個小時", "小时", "小時", "h", "hr", "hrs"]

    static func parse(_ raw: String) -> [ParsedTask] {
        raw.split(whereSeparator: \.isNewline).compactMap { line in
            var text = String(line).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return nil }

            text = replacingFirstMatch(bullet, in: text, with: "")

            var minutes = defaultMinutes
            let range = NSRange(text.startIndex..., in: text)
            if let match = duration.firstMatch(in: text, range: range),
               let valueRange = Range(match.range(at: 1), in: text),
               let unitRange = Range(match.range(at: 2), in: text),
               let value = Double(text[valueRange]),
               let whole = Range(match.range, in: text) {
                minutes = self.minutes(value: value, unit: String(text[unitRange]))
                text = String(text[..<whole.lowerBound]).trimmingCharacters(in: .whitespaces)
            }

            let cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: " ，,、-–—"))
            guard !cleaned.isEmpty else { return nil }
            return ParsedTask(title: cleaned, minutes: max(1, minutes))
        }
    }

    private static func minutes(value: Double, unit: String) -> Int {
        hourUnits.contains(unit.lowercased())
            ? Int((value * 60).rounded())
            : Int(value.rounded())
    }

    private static func replacingFirstMatch(_ regex: NSRegularExpression, in text: String, with template: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), let found = Range(match.range, in: text) else {
            return text
        }
        return text.replacingCharacters(in: found, with: template)
    }
}
