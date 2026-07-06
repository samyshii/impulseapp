//
//  AddItemSheet.swift
//  Impulse
//
//  The form that slides up when the user taps "Shelve it". Creates a
//  new ShelvedItem with a cooldown timer running, then closes itself.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price: Decimal = 0
    @State private var note = ""
    @State private var selectedCooldown: CooldownOption = .oneDay
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    @FocusState private var isNameFieldFocused: Bool

    // The save button only lights up once there's a name and a real price.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && price > 0
    }

    // The cooldown buttons above always show and behave normally — this
    // only changes the actual timer duration used behind the scenes, and
    // only in Debug builds with the Settings > Debug toggle turned on.
    private var cooldownDuration: TimeInterval {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugUseFastTestCooldowns") {
            return 10
        }
        #endif
        return selectedCooldown.duration
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameField
                    priceField
                    photoPicker
                    noteField
                    cooldownPicker
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Shelve an item")
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

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What is it?")
                .font(.headline)
            TextField("e.g. Noise-cancelling headphones", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFieldFocused)
        }
    }

    private var priceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How much?")
                .font(.headline)
            TextField("0.00", value: $price, format: .currency(code: "USD"))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }

    private var photoPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo (optional)")
                .font(.headline)

            ZStack(alignment: .topTrailing) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: 88, height: 88)
                            VStack(spacing: 4) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text("Add photo")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                        }
                    }
                }

                // Lets the user back out of a photo they already picked,
                // so a photo is never stuck once chosen.
                if selectedPhotoData != nil {
                    Button {
                        selectedPhotoItem = nil
                        selectedPhotoData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                            .font(.title3)
                    }
                    .offset(x: 6, y: -6)
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why do you want it?")
                .font(.headline)
            TextField("Optional", text: $note)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var cooldownPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cooldown")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CooldownOption.allCases) { option in
                    Button {
                        selectedCooldown = option
                    } label: {
                        Text(option.label)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                selectedCooldown == option ? Color.accentColor : Color.secondary.opacity(0.15)
                            )
                            .foregroundStyle(selectedCooldown == option ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Put it on the shelf")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    private func save() {
        // Checked before inserting: is this the very first item the user
        // has ever shelved? If so, the pre-permission screen should show
        // right after this sheet closes.
        let isFirstItemEver = !UserDefaults.standard.bool(forKey: "hasShelvedFirstItem")

        let item = ShelvedItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price,
            photoData: selectedPhotoData,
            note: note.isEmpty ? nil : note,
            cooldownEndsAt: .now.addingTimeInterval(cooldownDuration)
        )

        withAnimation {
            modelContext.insert(item)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Schedules (or re-groups) this item's Decision Time notification.
        NotificationScheduler.reconcileAll(context: modelContext)

        if isFirstItemEver {
            UserDefaults.standard.set(true, forKey: "hasShelvedFirstItem")
            UserDefaults.standard.set(true, forKey: "shouldShowNotificationPrePrompt")
        }

        dismiss()
    }
}

// The four cooldown lengths the user can choose between.
private enum CooldownOption: CaseIterable, Identifiable {
    case oneHour, oneDay, threeDays, sevenDays

    var id: Self { self }

    var label: String {
        switch self {
        case .oneHour: return "1 hour"
        case .oneDay: return "24 hours"
        case .threeDays: return "3 days"
        case .sevenDays: return "7 days"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .oneHour: return 60 * 60
        case .oneDay: return 60 * 60 * 24
        case .threeDays: return 60 * 60 * 24 * 3
        case .sevenDays: return 60 * 60 * 24 * 7
        }
    }
}

#Preview {
    AddItemSheet()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
