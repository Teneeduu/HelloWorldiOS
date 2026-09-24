import SwiftUI
import WidgetKit

@main
struct JoWidgets: WidgetBundle {
    var body: some Widget {
        QuoteWidget()
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

struct QuoteProvider: TimelineProvider {
    private let quotes = BundledQuotes.load()

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: quotes.first)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: Date(), quote: BundledQuotes.ofTheDay(quotes)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // A week of entries, one per day, so the line changes at midnight even
        // if the widget is never refreshed in between.
        let entries = (0..<7).compactMap { offset -> QuoteEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return QuoteEntry(date: day, quote: BundledQuotes.ofTheDay(quotes, on: day))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    var body: some View {
        content.widgetBackground()
    }

    @ViewBuilder
    private var content: some View {
        if let quote = entry.quote {
            switch family {
            case .accessoryInline:
                Text(quote.text)

            default:
                VStack(alignment: .leading, spacing: 3) {
                    Text(quote.text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .lineLimit(3)

                    if !quote.source.isEmpty {
                        Text("—— " + quote.source)
                            .font(.system(size: 11, design: .rounded))
                            .opacity(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("Jo")
        }
    }
}

struct QuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "JoQuoteWidget", provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("每日名言")
        .description("在锁屏上显示今天的一句话。")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

private extension View {
    /// iOS 17 wants every widget to declare its container background.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(.clear, for: .widget)
        } else {
            self
        }
    }
}
