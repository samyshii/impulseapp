//
//  ShelvedItem.swift
//  Impulse
//
//  An item the user put "on the shelf" instead of buying right away.
//

import Foundation
import SwiftData

// The four states an item can be in while it sits on the shelf.
enum ItemStatus: String, Codable {
    case waiting        // cooldown timer is still counting down
    case readyToDecide   // cooldown is over, user needs to decide
    case letGo           // user chose not to buy it (money saved)
    case bought          // user chose to buy it anyway
}

@Model
final class ShelvedItem {
    // A stable ID that survives across app launches, so a scheduled
    // notification can find its way back to this exact item later.
    var id: UUID

    // What the item is called, e.g. "Noise-cancelling headphones".
    var name: String

    // How much it costs, e.g. 199.99.
    var price: Decimal

    // A photo of the item, stored as raw image data. Optional because
    // the user might not add a photo.
    var photoData: Data?

    // A link to where the item can be bought. Optional.
    var link: String?

    // A short note on why the user wants it. Optional.
    var note: String?

    // When the item was shelved.
    var createdAt: Date

    // When the cooldown timer finishes and the user can decide.
    var cooldownEndsAt: Date

    // Where this item currently stands: waiting, readyToDecide, letGo, or bought.
    var status: ItemStatus

    // When the user made their final decision (let go or bought). Nil until then.
    var decidedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        photoData: Data? = nil,
        link: String? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        cooldownEndsAt: Date,
        status: ItemStatus = .waiting,
        decidedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.photoData = photoData
        self.link = link
        self.note = note
        self.createdAt = createdAt
        self.cooldownEndsAt = cooldownEndsAt
        self.status = status
        self.decidedAt = decidedAt
    }
}
