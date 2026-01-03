//
//  main_app.swift
//  created by Harri Hilding Smatt on 2026-01-14
//

import SwiftUI

@MainActor
var titlebarAppearsTransparent: Bool = true

@main
struct MainApp : App {
    @NSApplicationDelegateAdaptor(MainAppDelegate.self) var appDelegate

    var body : some Scene {
        WindowGroup {
            MainView()
                .background(.green)
        }
    }
}

class MainAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
