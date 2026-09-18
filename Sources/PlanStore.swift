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

struct Goal: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var deadline: Date?
    var target: Double
    var progress: Double
    var unit: String
    var createdAt = Date()

    var percent: Double {
        guard target > 0 else { return 0 }
        return min(100, max(0, progress / target * 100))
    }

    var daysLeft: Int? {
        guard let deadline else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: deadline)
        ).day
    }

    /// How much has to move each remaining day to still land it on time.
    var requiredPace: Double? {
        guard let days = daysLeft, days > 0, target > progress else { return nil }
        return (target - progress) / Double(days)
    }
}

/// Everything Jo knows lives in its own folder, so `plan.json` sits next to the
/// music and photos and can be read or backed up through the Files app.
final class PlanStore: ObservableObject {
    @Published private(set) var tasks: [PlanTask] = []
    @Published private(set) var goals: [Goal] = []

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

    // MARK: - Week

    /// The Monday-to-Sunday week that contains `date`.
    func weekDays(containing date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func summary(on day: Date) -> (done: Int, total: Int, minutes: Int) {
        let items = tasks(on: day)
        return (
            items.filter { $0.status == .done }.count,
            items.count,
            items.reduce(0) { $0 + $1.estimateMinutes }
        )
    }

    // MARK: - Review

    func undone(on day: Date) -> [PlanTask] {
        tasks(on: day).filter(\.isOpen)
    }

    /// Evening review action: push whatever is still open to the next day.
    func carryOverUndone(from day: Date, to target: Date) {
        let destination = calendar.startOfDay(for: target)
        for task in undone(on: day) {
            guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { continue }
            tasks[index].day = destination
        }
        save()
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        save()
    }

    func update(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index] = goal
        save()
    }

    func removeGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        save()
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

    private struct PlanFile: Codable {
        var tasks: [PlanTask]
        var goals: [Goal]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }

        if let file = try? Self.decoder.decode(PlanFile.self, from: data) {
            tasks = file.tasks
            goals = file.goals
            return
        }

        // Files written before goals existed are a bare array of tasks.
        if let legacy = try? Self.decoder.decode([PlanTask].self, from: data) {
            tasks = legacy
            save()
        }
    }

    private func save() {
        let file = PlanFile(tasks: tasks, goals: goals)
        guard let data = try? Self.encoder.encode(file) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
