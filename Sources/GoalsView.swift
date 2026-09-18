import SwiftUI

struct GoalsView: View {
    @ObservedObject var store: PlanStore
    @State private var editing: Goal?
    @State private var creating = false

    var body: some View {
        List {
            if store.goals.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("还没有目标。")
                            .foregroundStyle(.secondary)
                        Text("目标是回答「离终点还有多远」的东西：一本书的页数、一门课的章节、一个项目的进度。填上截止日，Jo 会算出每天还要推进多少。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("加一个目标") {
                            creating = true
                        }
                    }
                    .padding(.vertical, 6)
                }
            } else {
                ForEach(store.goals) { goal in
                    Button {
                        editing = goal
                    } label: {
                        row(for: goal)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        store.removeGoal(store.goals[index])
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    creating = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editing) { goal in
            GoalEditorView(store: store, goal: goal)
        }
        .sheet(isPresented: $creating) {
            GoalEditorView(store: store, goal: nil)
        }
    }

    private func row(for goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.title)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(Int(goal.percent))%")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: goal.percent, total: 100)
                .tint(tint(for: goal))

            Text(detail(for: goal))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func tint(for goal: Goal) -> Color {
        if goal.progress >= goal.target { return .green }
        if let days = goal.daysLeft, days < 0 { return .red }
        return .accentColor
    }

    private func detail(for goal: Goal) -> String {
        let amount = "\(trim(goal.progress)) / \(trim(goal.target)) \(goal.unit)"

        guard let days = goal.daysLeft else {
            return amount
        }
        if goal.progress >= goal.target {
            return amount + " · 已达成"
        }
        if days < 0 {
            return amount + " · 已过期 \(-days) 天"
        }
        if days == 0 {
            return amount + " · 今天到期"
        }
        guard let pace = goal.requiredPace else {
            return amount + " · 剩 \(days) 天"
        }
        return amount + " · 剩 \(days) 天，每天还要 \(trim(pace)) \(goal.unit)"
    }

    private func trim(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

struct GoalEditorView: View {
    @ObservedObject var store: PlanStore
    let goal: Goal?

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var unit = "%"
    @State private var target: Double = 100
    @State private var progress: Double = 0
    @State private var hasDeadline = false
    @State private var deadline = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("目标") {
                    TextField("想完成什么", text: $title)
                    TextField("单位（页 / 章 / 题 / %）", text: $unit)
                }

                Section("进度") {
                    LabeledContent("目标量") {
                        TextField("目标量", value: $target, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("已完成") {
                        TextField("已完成", value: $progress, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("截止") {
                    Toggle("有截止日", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("截止日", selection: $deadline, displayedComponents: .date)
                    }
                }

                if let goal {
                    Section {
                        Button("删除这个目标", role: .destructive) {
                            store.removeGoal(goal)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "新目标" : "改目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || target <= 0)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let goal else { return }
        title = goal.title
        unit = goal.unit
        target = goal.target
        progress = goal.progress
        hasDeadline = goal.deadline != nil
        deadline = goal.deadline ?? Date()
    }

    private func save() {
        let cleanedUnit = unit.trimmingCharacters(in: .whitespaces)
        var updated = goal ?? Goal(title: "", deadline: nil, target: 100, progress: 0, unit: "%")
        updated.title = title.trimmingCharacters(in: .whitespaces)
        updated.unit = cleanedUnit.isEmpty ? "%" : cleanedUnit
        updated.target = target
        updated.progress = progress
        updated.deadline = hasDeadline ? deadline : nil

        if goal == nil {
            store.addGoal(updated)
        } else {
            store.update(updated)
        }
        dismiss()
    }
}
