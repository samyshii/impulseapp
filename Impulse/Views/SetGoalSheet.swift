//
//  SetGoalSheet.swift
//  Impulse
//
//  A small form for creating the one savings goal shown on the Wins
//  tab. Opened from the "set a goal" prompt when none exists yet.
//

import SwiftUI
import SwiftData

struct SetGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetAmount: Decimal = 0

    @FocusState private var isNameFieldFocused: Bool

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
                    Text("Set Goal")
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
            .navigationTitle("New Goal")
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
        let goal = Goal(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            targetAmount: targetAmount
        )
        modelContext.insert(goal)
        dismiss()
    }
}

#Preview {
    SetGoalSheet()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
