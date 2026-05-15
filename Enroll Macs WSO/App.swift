//
//  Enroll_Macs_WSOApp_Main.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI
import AppKit
import Metal

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }

        guard MTLCreateSystemDefaultDevice() != nil else {
            fatalError("Metal is not supported on this device")
        }
    }
}

// MARK: - Main App
@main
struct Enroll_Macs_WSOApp: App {
    @AppStorage("isConfigured") private var isConfigured: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MachineListView()
                .frame(minWidth: 1050, minHeight: 400)
        }
        .commandsRemoved()
        .commands {
            AppMenuCommands()
            FileMenuCommands()
            EditMenuCommands()
        }
        .defaultSize(width: 1050, height: 600)
    }
}

// MARK: - Menu Commands
struct AppMenuCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("À propos de l'application") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
        }

        CommandGroup(replacing: .appTermination) {
            Button("Quitter") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

struct FileMenuCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            // Supprime le groupe "Nouveau"
        }

        CommandGroup(after: .newItem) {
            Button("Fermer la fenêtre") {
                if let keyWindow = NSApplication.shared.keyWindow {
                    keyWindow.performClose(nil)
                }
            }
            .keyboardShortcut("w")
        }
    }
}

struct EditMenuCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Couper") {
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("x")

            Button("Copier") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("c")

            Button("Coller") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v")
        }
    }
}
