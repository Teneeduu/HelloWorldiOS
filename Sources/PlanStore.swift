import Foundation

enum TaskStatus: String, Codable {
    case todo
    case done
}

struct PlanTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var day: Date
    var status: TaskStatus = .todo
    var estimateMinutes: Int
    var createdAt = Date()
    var doneAt: Date?

    var isOpen: Bool { status == .todo }
}

/// Everything Jo knows lives in its own folder, so `plan.json` sits next to the
/// music and photos and can be read or backed up through the Files app.
final class PlanStore: ObservableObject {
    @Published private(set) var tasks: [PlanTask] = []

    private let calendar = Calendar.current

    var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("plan.json")
    }

    init() {
        load()
    }

    // MARK: - Today

    var todayTasks: [PlanTask] {
        tasks(on: Date())
    }

    var todayDone: Int {
        todayTasks.filter { $0.status == .done }.count
    }

    var todayMinutes: Int {
        todayTasks.reduce(0) { $0 + $1.estimateMinutes }
    }

    var todayRemainingMinutes: Int {
        todayTasks.filter(\.isOpen).reduce(0) { $0 + $1.estimateMinutes }
    }

    func tasks(on day: Date) -> [PlanTask] {
        tasks
            .filter { calendar.isDate($0.day, inSameDayAs: day) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Editing

    func add(_ parsed: [ParsedTask], on day: Date = Date()) {
        let start = calendar.startOfDay(for: day)
        for item in parsed {
            tasks.append(PlanTask(title: item.title, day: start, estimateMinutes: item.minutes))
        }
        save()
    }

    func toggle(_ task: PlanTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        if tasks[index].status == .done {
            tasks[index].status = .todo
            tasks[index].doneAt = nil
        } else {
            tasks[index].status = .done
            tasks[index].doneAt = Date()
        }
        save()
    }

    func remove(_ task: PlanTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func reload() {
        load()
    }

    // MARK: - Storage

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? Self.decoder.decode([PlanTask].self, from: data)
        else { return }
        tasks = decoded
    }

    private func save() {
        guard let data = try? Self.encoder.encode(tasks) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
