//
//  YeelightMacApp.swift
//  YeelightMac
//
//  Created by John Greenwood on 18.05.2021.
//

import SwiftUI

@main
struct YeelightMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
//            MainView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var popover      : NSPopover!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        createMenuItem()
    }
    
    private func createMenuItem() {
        let contentView = MainV()
        popover = .init()
        popover.contentSize = .init(width: 300, height: 100)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
             button.image = NSImage(named: "Icon")
             button.action = #selector(togglePopover(_:))
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusBarItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }
}
