//
//  ShelfView.swift
//  Impulse
//
//  The main "Shelf" tab: everything the user has shelved that hasn't
//  been decided on yet, each with a live countdown.
//

import SwiftUI
import SwiftData
import Combine

struct ShelfView: View {
    @Query private var allItems: [ShelvedItem]

    // Ticks once a second so the countdowns and the "ready to decide"
    // sort order stay live without any manual refresh.
    @State private var now: Date = .now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Controls the "Shelve it" add-item sheet.
    @State private var isShowingAddItem = false

    // The item currently open in the decision flow, if any.
    @State private var decidingItem: ShelvedItem?

    // Only items still waiting on a decision belong on the shelf.
    // Items whose cooldown has already ended float to the very top.
    private var shelfItems: [ShelvedItem] {
        allItems
            .filter { $0.status == .waiting || $0.status == .readyToDecide }
            .sorted { lhs, rhs in
                let lhsReady = lhs.cooldownEndsAt <= now
                let rhsReady = rhs.cooldownEndsAt <= now
                if lhsReady != rhsReady {
                    return lhsReady
                }
                return lhs.cooldownEndsAt < rhs.cooldownEndsAt
            }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    greetingHeader

                    if shelfItems.isEmpty {
                        emptyState
                    } else {
                        itemList
                    }
                }

                shelveButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onReceive(timer) { tick in
            now = tick
        }
        .sheet(isPresented: $isShowingAddItem) {
            AddItemSheet()
        }
        .fullScreenCover(item: $decidingItem) { item in
            DecisionFlowView(item: item)
        }
    }

    // A friendly, time-of-day-aware header shown above everything else.
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.largeTitle.bold())
            Text("Here's what's on your shelf.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Still up?"
        }
    }

    // The scrolling list of item cards.
    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(shelfItems) { item in
                    ShelvedItemCard(item: item, now: now)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if item.cooldownEndsAt <= now {
                                decidingItem = item
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80) // leaves room so the floating button doesn't cover the last card
        }
    }

    // Shown instead of the list when nothing has been shelved yet.
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nothing on the shelf yet")
                .font(.headline)
            Text("See something you want to buy? Shelve it first and let the cooldown talk you through it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // The floating "add" button, pinned to the bottom-right corner.
    private var shelveButton: some View {
        Button {
            isShowingAddItem = true
        } label: {
            Label("Shelve it", systemImage: "plus")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
                .shadow(radius: 4, y: 2)
        }
        .padding()
    }
}

#Preview {
    ShelfView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
