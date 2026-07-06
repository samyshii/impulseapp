//
//  OnboardingGoalPage.swift
//  Impulse
//
//  Onboarding page 2: an optional first savings goal. Not required —
//  "Skip for now" moves on without setting one.
//

import SwiftUI

struct OnboardingGoalPage: View {
    @Binding var goalName: String
    @Binding var goalTarget: Decimal
    var onNext: () -> Void
    var onSkip: () -> Void

    @FocusState private var isNameFieldFocused: Bool

    private var canContinue: Bool {
        !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goalTarget > 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Set your first goal")
                    .font(.title.bold())
                Text("What are you saving toward? You can always change this later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you saving for?")
                        .font(.headline)
                    TextField("e.g. Concert tickets", text: $goalName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFieldFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Target amount")
                        .font(.headline)
                    TextField("0.00", value: $goalTarget, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)

                Button("Skip for now", action: onSkip)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    OnboardingGoalPage(goalName: .constant(""), goalTarget: .constant(0), onNext: {}, onSkip: {})
}
