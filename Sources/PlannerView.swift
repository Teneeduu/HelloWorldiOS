import SwiftUI

struct PlannerView: View {
    @ObservedObject var store: PlanStore
    @State private var showInput = false

    private var tasks: [PlanTask] { store.todayTasks }

    var body: some View {
        NavigationStack {
            List {
                if !tasks.isEmpty {
                    summarySection
                }
                taskSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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
                MorningInputView(store: store)
            }
        }
    }

    private var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(store.todayDone) / \(tasks.count)")
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

                ProgressView(value: Double(store.todayDone), total: Double(max(tasks.count, 1)))
                    .tint(store.todayDone == tasks.count ? .green : .accentColor)
            }
            .padding(.vertical, 4)
        }
    }

    private var remainingText: String {
        let left = store.todayRemainingMinutes
        if left == 0 {
            return "都做完了"
        }
        if left >= 60 {
            let hours = Double(left) / 60
            return String(format: "还剩 %.1f 小时", hours)
        }
        return "还剩 \(left) 分钟"
    }

    private var taskSection: some View {
        Section("今天") {
            if tasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("今天还没排计划。")
                        .foregroundStyle(.secondary)
                    Button("排一下今天") {
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

struct MorningInputView: View {
    @ObservedObject var store: PlanStore
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
                    Text("今天打算干点什么")
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
                            Text("\(parsed.count) 件 · \(totalMinutes)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("排今天")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("就这样") {
                        store.add(parsed)
                        dismiss()
                    }
                    .disabled(parsed.isEmpty)
                }
            }
        }
    }

    private var totalMinutes: String {
        let total = parsed.reduce(0) { $0 + $1.minutes }
        if total >= 60 {
            return String(format: "%.1f 小时", Double(total) / 60)
        }
        return "\(total) 分钟"
    }
}
