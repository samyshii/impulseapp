//
//  SettingsView.swift
//  Impulse
//
//  The Settings tab: notification preferences, goal management, app
//  info, and data controls.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]

    // Saved now even though the actual notifications aren't wired up yet.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyDecisionTime") private var notifyDecisionTime = true
    @AppStorage("notifyWeeklyRecap") private var notifyWeeklyRecap = true
    @AppStorage("notifyStreakGuard") private var notifyStreakGuard = true
    @AppStorage("notifyMilestones") private var notifyMilestones = true
    @AppStorage("notifyWinBack") private var notifyWinBack = true

    @State private var isShowingGoalSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var exportURL: URL?

    private var goal: Goal? { goals.first }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                goalSection
                aboutSection
                dataSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingGoalSheet) {
                SetGoalSheet(goalToEdit: goal)
            }
            .alert("Delete All Data?", isPresented: $isShowingDeleteConfirmation) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes every shelved item, your goal, and your saved totals. This can't be undone.")
            }
            .onAppear {
                exportURL = makeExportFile()
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle("Notifications", isOn: $notificationsEnabled)

            Toggle("Decision Time alerts", isOn: $notifyDecisionTime)
                .disabled(!notificationsEnabled)
            Toggle("Weekly Recap", isOn: $notifyWeeklyRecap)
                .disabled(!notificationsEnabled)
            Toggle("Streak Guard", isOn: $notifyStreakGuard)
                .disabled(!notificationsEnabled)
            Toggle("Milestone surprises", isOn: $notifyMilestones)
                .disabled(!notificationsEnabled)
            Toggle("Win-back messages", isOn: $notifyWinBack)
                .disabled(!notificationsEnabled)
        } header: {
            Text("Notifications")
        } footer: {
            Text("These are saved now, but the actual alerts haven't been built yet.")
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        Section("Goal") {
            if let goal {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                    Text("Target: \(goal.targetAmount.formatted(.currency(code: "USD")))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button("Edit Goal") {
                    isShowingGoalSheet = true
                }
            } else {
                Text("No goal set yet.")
                    .foregroundStyle(.secondary)
                Button("Set a Goal") {
                    isShowingGoalSheet = true
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Privacy Policy")
                Spacer()
                Text("Coming soon")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Terms of Use")
                Spacer()
                Text("Coming soon")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }
            } else {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
        }
    }

    private func deleteAllData() {
        try? modelContext.delete(model: ShelvedItem.self)
        try? modelContext.delete(model: Goal.self)
        try? modelContext.delete(model: AppStats.self)
    }

    // MARK: - Export

    // Writes everything to a JSON file in the temp directory and
    // returns its URL so the Export row can share it.
    private func makeExportFile() -> URL? {
        struct ExportedItem: Codable {
            let name: String
            let price: Decimal
            let note: String?
            let status: String
            let createdAt: Date
            let cooldownEndsAt: Date
            let decidedAt: Date?
        }
        struct ExportedData: Codable {
            let totalSaved: Decimal
            let currentWeeklyStreak: Int
            let goalName: String?
            let goalTarget: Decimal?
            let items: [ExportedItem]
        }

        let stats = (try? modelContext.fetch(FetchDescriptor<AppStats>()))?.first
        let items = (try? modelContext.fetch(FetchDescriptor<ShelvedItem>())) ?? []

        let payload = ExportedData(
            totalSaved: stats?.totalSaved ?? 0,
            currentWeeklyStreak: stats?.currentWeeklyStreak ?? 0,
            goalName: goal?.name,
            goalTarget: goal?.targetAmount,
            items: items.map {
                ExportedItem(
                    name: $0.name,
                    price: $0.price,
                    note: $0.note,
                    status: $0.status.rawValue,
                    createdAt: $0.createdAt,
                    cooldownEndsAt: $0.cooldownEndsAt,
                    decidedAt: $0.decidedAt
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(payload) else { return nil }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("impulse-export.json")
        try? data.write(to: url)
        return url
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
