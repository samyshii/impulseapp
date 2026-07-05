//
//  NotificationRouter.swift
//  Impulse
//
//  When the user taps a notification, something needs to tell the app
//  which screen to jump to. NotificationManager figures out where a tap
//  should go and writes it here; MainTabView and ShelfView watch this
//  and react by switching tabs or opening the right sheet.
//

import Foundation
import Combine

// Every place a notification can take the user.
enum NotificationDestination: Equatable {
    case shelf
    case wins
    case settings
    case decisionItem(UUID) // a specific shelved item, by its stable id
}

@MainActor
final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()

    // The single source of truth for "where should we navigate right
    // now?". Views clear this back to nil once they've acted on it.
    @Published var destination: NotificationDestination?

    private init() {}
}
