import SwiftUI

@main
struct MoneyStopwatchApp: App {
    @State private var persistence = PersistenceController.shared
    @State private var sessionTimer = SessionTimer()
    @State private var transferInbox = TransferInbox()

    init() {
        UserDefaults.standard.register(defaults: [
            "UserRate": 19.0,
            "AnnualSalary": 50_000.0,
            "AnnualWorkingHours": 2_080.0,
            "PlayfulLanguage": true
        ])
    }

    var body: some Scene {
        WindowGroup {
            AppView(
                sessionTimer: sessionTimer,
                persistence: persistence,
                transferInbox: transferInbox
            )
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(transferInbox)
        }
    }
}

private struct AppView: View {
    let sessionTimer: SessionTimer
    let persistence: PersistenceController
    let transferInbox: TransferInbox

    var body: some View {
        TabView {
            Tab("Timer", systemImage: "stopwatch") {
                NavigationStack {
                    StopwatchView(timer: sessionTimer)
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryView()
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onOpenURL { url in
            transferInbox.receive(.success(url))
        }
        .confirmationDialog(
            "Import \(transferInbox.pendingArchive?.entries.count ?? 0) sessions?",
            isPresented: pendingArchiveBinding,
            titleVisibility: .visible
        ) {
            Button("Merge with This Device") {
                transferInbox.applyPendingArchive(
                    mode: .merge,
                    to: persistence.container.viewContext
                )
            }
            Button("Replace This Device’s History", role: .destructive) {
                transferInbox.applyPendingArchive(
                    mode: .replace,
                    to: persistence.container.viewContext
                )
            }
            Button("Cancel", role: .cancel) {
                transferInbox.pendingArchive = nil
            }
        } message: {
            if transferInbox.pendingArchive?.settings != nil {
                Text("The transferred hourly rate, salary, working hours, and language preference will also be applied.")
            } else {
                Text("This transfer contains session history only. Your settings won’t change.")
            }
        }
        .alert("Transfer", isPresented: transferNoticeBinding) {
            Button("OK", role: .cancel) {
                transferInbox.notice = nil
            }
        } message: {
            if let notice = transferInbox.notice {
                Text("\(notice.title)\n\n\(notice.message)")
            }
        }
        .alert("History Unavailable", isPresented: persistenceErrorBinding) {
            Button("OK", role: .cancel) {
                persistence.clearError()
            }
        } message: {
            Text(persistence.errorMessage ?? "The history store couldn’t be opened.")
        }
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { persistence.errorMessage != nil },
            set: { if !$0 { persistence.clearError() } }
        )
    }

    private var pendingArchiveBinding: Binding<Bool> {
        Binding(
            get: { transferInbox.pendingArchive != nil },
            set: { if !$0 { transferInbox.pendingArchive = nil } }
        )
    }

    private var transferNoticeBinding: Binding<Bool> {
        Binding(
            get: { transferInbox.notice != nil },
            set: { if !$0 { transferInbox.notice = nil } }
        )
    }
}
