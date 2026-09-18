import SwiftUI

struct PlannerView: View {
    @ObservedObject var store: PlanStore
    @State private var tab: Tab = .today

    enum Tab: String, CaseIterable, Identifiable {
        case today = "今日"
        case week = "本周"
        case goals = "目标"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                switch tab {
                case .today:
                    DayTaskList(store: store, day: Date(), showsReview: true)
                case .week:
                    WeekList(store: store)
                case .goals:
                    GoalsView(store: store)
                }
            }
            .navigationTitle(tab == .today ? PlanFormat.dayTitle(Date()) : "计划")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

enum PlanFormat {
    static func dayTitle(_ day: Date) -> String {
        format(day, as: "M月d日 EEEE")
    }

    static func weekday(_ day: Date) -> String {
        format(day, as: "EEE")
    }

    static func shortDate(_ day: Date) -> String {
        format(day, as: "M/d")
    }

    static func minutes(_ total: Int) -> String {
        total >= 60 ? String(format: "%.1f 小时", Double(total) / 60) : "\(total) 分钟"
    }

    private static func format(_ day: Date, as pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = pattern
        return formatter.string(from: day)
    }
}

struct DayTaskList: View {
    @ObservedObject var store: PlanStore
    let day: Date
    var showsReview = false
    @State private var showInput = false

    private var tasks: [PlanTask] { store.tasks(on: day) }

    var body: some View {
        List {
            if !tasks.isEmpty {
                summarySection
            }
            taskSection
            if showsReview, !tasks.isEmpty {
                reviewSection
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInput = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showInput) {
            MorningInputView(store: store, day: day)
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(store.summary(on: day).done) / \(tasks.count)")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    Text("件")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(remainingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView(
                    value: Double(store.summary(on: day).done),
                    total: Double(max(tasks.count, 1))
                )
                .tint(store.undone(on: day).isEmpty ? .green : .accentColor)
            }
            .padding(.vertical, 4)
        }
    }

    private var remainingText: String {
        let left = store.undone(on: day).reduce(0) { $0 + $1.estimateMinutes }
        return left == 0 ? "都做完了" : "还剩 " + PlanFormat.minutes(left)
    }

    private var taskSection: some View {
        Section(showsReview ? "今天" : "这天") {
            if tasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("还没排计划。")
                        .foregroundStyle(.secondary)
                    Button("排一下") {
                        showInput = true
                    }
                }
                .padding(.vertical, 6)
            } else {
                ForEach(tasks) { task in
                    Button {
                        store.toggle(task)
                    } label: {
                        row(for: task)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        store.remove(tasks[index])
                    }
                }
            }
        }
    }

    private var reviewSection: some View {
        Section("复盘") {
            LabeledContent("预计投入", value: PlanFormat.minutes(store.summary(on: day).minutes))

            let open = store.undone(on: day)
            if open.isEmpty {
                Text("今天清空了。")
                    .foregroundStyle(.secondary)
            } else if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: day) {
                Button("把没做完的 \(open.count) 件挪到明天") {
                    store.carryOverUndone(from: day, to: tomorrow)
                }
            }
        }
    }

    private func row(for task: PlanTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.status == .done ? .green : .secondary)

            Text(task.title)
                .strikethrough(task.status == .done)
                .foregroundStyle(task.status == .done ? .secondary : .primary)

            Spacer()

            Text("\(task.estimateMinutes) 分")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

struct WeekList: View {
    @ObservedObject var store: PlanStore

    private var days: [Date] { store.weekDays(containing: Date()) }

    var body: some View {
        List {
            Section {
                ForEach(days, id: \.self) { day in
                    NavigationLink {
                        DayTaskList(store: store, day: day)
                            .navigationTitle(PlanFormat.dayTitle(day))
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        row(for: day)
                    }
                }
            } footer: {
                Text("本周 \(weekTotals.done) / \(weekTotals.total) 件，预计 \(PlanFormat.minutes(weekTotals.minutes))。")
            }
        }
    }

    private var weekTotals: (done: Int, total: Int, minutes: Int) {
        days.reduce((done: 0, total: 0, minutes: 0)) { running, day in
            let summary = store.summary(on: day)
            return (running.done + summary.done, running.total + summary.total, running.minutes + summary.minutes)
        }
    }

    private func row(for day: Date) -> some View {
        let summary = store.summary(on: day)
        let isToday = Calendar.current.isDateInToday(day)

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(PlanFormat.weekday(day))
                    .font(.body.weight(isToday ? .semibold : .regular))
                Text(PlanFormat.shortDate(day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(isToday ? Color.accentColor : .primary)

            Spacer()

            if summary.total == 0 {
                Text("—")
                    .foregroundStyle(.tertiary)
            } else {
                Text("\(summary.done)/\(summary.total)")
                    .monospacedDigit()
                    .foregroundStyle(summary.done == summary.total ? .green : .secondary)
            }
        }
    }
}

struct MorningInputView: View {
    @ObservedObject var store: PlanStore
    var day: Date = Date()
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var parsed: [ParsedTask] { TaskParser.parse(text) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                } header: {
                    Text(Calendar.current.isDateInToday(day) ? "今天打算干点什么" : PlanFormat.dayTitle(day) + "打算干点什么")
                } footer: {
                    Text("一行一件事，时长写在行尾：2小时 / 45分钟 / 1.5h /（50分钟）。不写按 30 分钟算。")
                }

                if !parsed.isEmpty {
                    Section("这样排行吗") {
                        ForEach(parsed) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                Text("\(item.minutes) 分")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text("合计")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(parsed.count) 件 · \(PlanFormat.minutes(totalMinutes))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("排计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("就这样") {
                        store.add(parsed, on: day)
                        dismiss()
                    }
                    .disabled(parsed.isEmpty)
                }
            }
        }
    }

    private var totalMinutes: Int {
        parsed.reduce(0) { $0 + $1.minutes }
    }
}
