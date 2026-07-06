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
    @Environment(\.openURL) private var openURL
    @Query private var goals: [Goal]

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyDecisionTime") private var notifyDecisionTime = true
    @AppStorage("notifyWeeklyRecap") private var notifyWeeklyRecap = true
    @AppStorage("notifyStreakGuard") private var notifyStreakGuard = true
    @AppStorage("notifyMilestones") private var notifyMilestones = true
    @AppStorage("notifyWinBack") private var notifyWinBack = true

    // When the weekly recap fires — a day of the week (1 = Sunday ...
    // 7 = Saturday, matching Foundation's Calendar) plus an hour/minute.
    // Defaults to Sunday 6pm.
    @AppStorage("weeklyRecapWeekday") private var weeklyRecapWeekday = 1
    @AppStorage("weeklyRecapHour") private var weeklyRecapHour = 18
    @AppStorage("weeklyRecapMinute") private var weeklyRecapMinute = 0

    @State private var isShowingGoalSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingPermissionDeniedAlert = false
    @State private var exportURL: URL?

    #if DEBUG
    @AppStorage("debugUseFastTestCooldowns") private var debugUseFastTestCooldowns = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var isShowingWeeklyRecapPreview = false
    @State private var weeklyRecapPreviewData: WeeklyRecapData?
    #endif

    private let weekdaySymbols = Calendar.current.weekdaySymbols

    // A Date binding just so DatePicker has something to show/edit; the
    // real source of truth is the hour/minute AppStorage above.
    private var weeklyRecapTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = weeklyRecapHour
                components.minute = weeklyRecapMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                weeklyRecapHour = components.hour ?? 18
                weeklyRecapMinute = components.minute ?? 0
                NotificationScheduler.reconcileAll(context: modelContext)
            }
        )
    }

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
                #if DEBUG
                debugSection
                #endif
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
            #if DEBUG
            // Attached here at the top level, not down on debugSection's
            // Section — a fullScreenCover nested inside a Form row can
            // present with stale/empty content instead of what's current.
            .fullScreenCover(isPresented: $isShowingWeeklyRecapPreview) {
                if let weeklyRecapPreviewData {
                    WeeklyRecapView(data: weeklyRecapPreviewData) {
                        isShowingWeeklyRecapPreview = false
                    }
                }
            }
            #endif
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle("Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, isOn in
                    if isOn {
                        Task { await handleMasterToggleOn() }
                    } else {
                        NotificationScheduler.reconcileAll(context: modelContext)
                    }
                }

            Toggle("Decision Time alerts", isOn: $notifyDecisionTime)
                .disabled(!notificationsEnabled)
                .onChange(of: notifyDecisionTime) { _, _ in NotificationScheduler.reconcileAll(context: modelContext) }

            Toggle("Weekly Recap", isOn: $notifyWeeklyRecap)
                .disabled(!notificationsEnabled)
                .onChange(of: notifyWeeklyRecap) { _, _ in NotificationScheduler.reconcileAll(context: modelContext) }

            if notificationsEnabled && notifyWeeklyRecap {
                Picker("Recap day", selection: $weeklyRecapWeekday) {
                    ForEach(1...7, id: \.self) { index in
                        Text(weekdaySymbols[index - 1]).tag(index)
                    }
                }
                .onChange(of: weeklyRecapWeekday) { _, _ in NotificationScheduler.reconcileAll(context: modelContext) }

                DatePicker("Recap time", selection: weeklyRecapTimeBinding, displayedComponents: .hourAndMinute)
            }

            Toggle("Streak Guard", isOn: $notifyStreakGuard)
                .disabled(!notificationsEnabled)
                .onChange(of: notifyStreakGuard) { _, _ in NotificationScheduler.reconcileAll(context: modelContext) }
            Toggle("Milestone surprises", isOn: $notifyMilestones)
                .disabled(!notificationsEnabled)
            Toggle("Win-back messages", isOn: $notifyWinBack)
                .disabled(!notificationsEnabled)
                .onChange(of: notifyWinBack) { _, _ in NotificationScheduler.reconcileAll(context: modelContext) }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Quiet hours: nothing from Impulse is ever delivered between 9pm and 9am. Anything due then waits until 9:05am instead.")
        }
        .alert("Notifications are turned off", isPresented: $isShowingPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("To get alerts from Impulse, turn on notifications for this app in iOS Settings.")
        }
    }

    // Called when the master toggle is switched on. Requests the real
    // system permission if we've never asked, or points the user at iOS
    // Settings if they'd previously said no (Apple only lets an app ask
    // once — after that, only the Settings app can turn it back on).
    private func handleMasterToggleOn() async {
        switch await NotificationManager.shared.authorizationStatus() {
        case .notDetermined:
            let granted = await NotificationManager.shared.requestAuthorization()
            if !granted {
                notificationsEnabled = false
            }
            NotificationScheduler.reconcileAll(context: modelContext)
        case .denied:
            isShowingPermissionDeniedAlert = true
        default:
            NotificationScheduler.reconcileAll(context: modelContext)
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

    #if DEBUG
    // MARK: - Debug (never shown in a Release/TestFlight/App Store build)

    private var debugSection: some View {
        Section {
            Toggle("Bypass quiet hours", isOn: debugBypassQuietHoursBinding)
            Toggle("Use fast test cooldowns", isOn: $debugUseFastTestCooldowns)
            Button("Reset onboarding") {
                withAnimation {
                    hasCompletedOnboarding = false
                }
            }
            Button("Preview Weekly Recap") {
                let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
                let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.end ?? .now
                weeklyRecapPreviewData = WeeklyRecapData.compute(context: modelContext, from: weekStart, to: weekEnd)
                isShowingWeeklyRecapPreview = true
            }
        } header: {
            Text("Debug")
        } footer: {
            Text("Testing only. \"Bypass quiet hours\" fires notifications at their real computed time even between 9pm and 9am. \"Fast test cooldowns\" makes any item shelved from now on ready in 10 seconds, no matter which cooldown button you tap — existing shelved items aren't affected. \"Reset onboarding\" shows the welcome flow again immediately, without deleting any of your data. \"Preview Weekly Recap\" opens the recap screen right now using this week's real data so far, regardless of what day it is.")
        }
    }

    private var debugBypassQuietHoursBinding: Binding<Bool> {
        Binding(
            get: { UserDefaults.standard.bool(forKey: "debugBypassQuietHours") },
            set: { newValue in
                UserDefaults.standard.set(newValue, forKey: "debugBypassQuietHours")
                // Re-run scheduling now so anything already pushed to
                // 9:05am gets rescheduled at its real, un-adjusted time.
                NotificationScheduler.reconcileAll(context: modelContext)
            }
        )
    }
    #endif

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
