//
//  PrePermissionView.swift
//  Impulse
//
//  Shown exactly once, right after the user shelves their very first
//  item ever — before Apple's real system permission popup appears.
//  Explains why notifications are useful so the system prompt (which
//  only iOS lets you ask once) lands after the user already wants it.
//

import SwiftUI

struct PrePermissionView: View {
    @Environment(\.modelContext) private var modelContext

    // Called once the user has made a choice (either way), so the
    // presenting view can dismiss this screen.
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Want a heads-up when this timer ends?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("That's the whole point of the shelf.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: allow) {
                    Text("Yes, notify me")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Not now", action: onFinished)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func allow() {
        Task {
            await NotificationManager.shared.requestAuthorization()
            // Now that permission may have just been granted, reschedule
            // everything so the item(s) already on the shelf get their
            // Decision Time notifications for real.
            NotificationScheduler.reconcileAll(context: modelContext)
            onFinished()
        }
    }
}

#Preview {
    PrePermissionView(onFinished: {})
}
