//
//  ContentView.swift
//  Impulse
//
//  Temporary screen just to prove the data models save and load
//  correctly. This will be replaced by the real "shelf" screen once
//  we build the actual add-item and cooldown flow.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShelvedItem.createdAt, order: .reverse) private var items: [ShelvedItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text("\(item.price.formatted(.currency(code: "USD"))) — \(item.status.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Impulse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addTestItem) {
                        Label("Add Test Item", systemImage: "plus")
                    }
                }
            }
        }
    }

    // Creates a sample shelved item so we can see the models working
    // on screen. The real "add item" screen comes in a later step.
    private func addTestItem() {
        withAnimation {
            let item = ShelvedItem(
                name: "Test Item \(items.count + 1)",
                price: 19.99,
                cooldownEndsAt: Calendar.current.date(byAdding: .minute, value: 1, to: .now) ?? .now
            )
            modelContext.insert(item)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ShelvedItem.self, Goal.self, AppStats.self], inMemory: true)
}
