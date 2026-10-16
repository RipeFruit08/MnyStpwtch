import CoreData
import SwiftUI
import UniformTypeIdentifiers

struct TransferDataView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(TransferInbox.self) private var transferInbox
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeEntry.date, ascending: false)]
    ) private var entries: FetchedResults<TimeEntry>

    @State private var isImporting = false

    private var exportArchive: MoneyStopwatchArchive {
        MoneyStopwatchArchive(entries: Array(entries))
    }

    var body: some View {
        List {
            TransferExplanationSection()

            Section {
                ShareLink(
                    "Send with AirDrop or Share",
                    item: exportArchive,
                    preview: SharePreview("Money Stopwatch Transfer")
                )

                LabeledContent("Sessions", value: entries.count.formatted())
            } header: {
                Text("Send")
            } footer: {
                Text("Creates a snapshot containing your saved sessions and app settings. An active timer is never included.")
            }

            Section {
                Button("Choose Transfer File", systemImage: "square.and.arrow.down") {
                    isImporting = true
                }
            } header: {
                Text("Receive")
            } footer: {
                Text("Merge keeps existing sessions and skips duplicates. Replace removes this device’s history first. Both options import the transferred settings.")
            }
        }
        .navigationTitle("Transfer Data")
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.moneyStopwatchArchive]
        ) { result in
            transferInbox.receive(result)
        }
        .task {
            do {
                try ensureEntryIdentifiers()
            } catch {
                transferInbox.notice = TransferNotice(
                    title: "Couldn’t Prepare Transfer",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func ensureEntryIdentifiers() throws {
        var madeChanges = false
        for entry in entries where entry.id == nil {
            entry.id = UUID()
            madeChanges = true
        }
        if madeChanges {
            try context.save()
        }
    }

}

private struct TransferExplanationSection: View {
    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device-to-device snapshots")
                        .font(.headline)
                    Text("Send your data directly with AirDrop, or save a transfer file for later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "iphone.and.arrow.forward.outward")
                    .foregroundStyle(.tint)
            }
        }
    }
}
