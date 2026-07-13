//
//  SetGoalSheet.swift
//  Impulse
//
//  A small form for creating or editing the one savings goal. Used
//  both by the Wins tab's "set a goal" prompt (no goalToEdit) and by
//  Settings' "Edit Goal" row (goalToEdit set to the existing goal).
//

import SwiftUI
import SwiftData

struct SetGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // When set, editing this goal in place; otherwise a new goal is
    // created on save.
    private var goalToEdit: Goal?

    @State private var name: String
    @State private var targetAmount: Decimal

    @FocusState private var isNameFieldFocused: Bool

    init(goalToEdit: Goal? = nil) {
        self.goalToEdit = goalToEdit
        _name = State(initialValue: goalToEdit?.name ?? "")
        _targetAmount = State(initialValue: goalToEdit?.targetAmount ?? 0)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetAmount > 0
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you saving for?")
                        .font(.headline)
                    TextField("e.g. New laptop", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFieldFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Target amount")
                        .font(.headline)
                    TextField("0.00", value: $targetAmount, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }

                Spacer()

                Button(action: save) {
                    Text(goalToEdit == nil ? "Set Goal" : "Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? Color.accentColor : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSave)
            }
            .padding()
            .navigationTitle(goalToEdit == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let goalToEdit {
            // `update` rather than setting the fields directly, so the
            // starter boost gets recalculated for the new target.
            goalToEdit.update(name: trimmedName, targetAmount: targetAmount)
        } else {
            let goal = Goal(name: trimmedName, targetAmount: targetAmount)
            modelContext.insert(goal)
        }

        dismiss()
    }
}

#Preview {
    SetGoalSheet()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
