//
//  MainC.swift
//  YeelightMac
//
//  Created by John Greenwood on 24.07.2021.
//

import SwiftUI

class MainC: NSObject, ObservableObject {
    
    @Published var previewImage: NSImage?
    @Published var isCapturing = false
    
    var selectedScreen = NSScreen.screens.first!
    var updateSpeed: TimeInterval = 0.5
    var diffSense = 10
    
    var downButtons = [DownButtonModel]()
    
    private var lastColor: NSColor?
    
    var connectionText: String {
        get {
            if yl.address == "" || yl.address == nil {
                return "Not connected"
            } else {
                if yl.connected {
                    return yl.address!
                } else {
                    return "Reconnecting..."
                }
            }
        }
    }
    
    private var yl = Yeelight()
    
    private var cTimer: Timer?
    
    override init() {
        super.init()
        createDownButtonActions()
    }
    
    func power(_ on: Bool) {
        on ? yl.switchOn() : yl.switchOff()
    }
    
    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }
    
    func setColor(_ color: NSColor) {
        guard color != lastColor else { return }
        
        let diffH = abs((lastColor?.HSB.hue ?? 0) - color.HSB.hue)
        let diffS = abs((lastColor?.HSB.saturation ?? 0) - color.HSB.saturation)
        let diffB = abs((lastColor?.HSB.brightness ?? 0) - color.HSB.brightness)
        
        if diffH > diffSense || diffS > diffSense {
            yl.setColor(h: Int(color.HSB.hue), s: Int(color.HSB.saturation))
        }
        
        if diffB > diffSense {
            yl.setBrightness(value: color.HSB.brightness)
        }
        
        lastColor = color
    }
    
    func startCapture() {
        isCapturing = true
        cTimer?.invalidate()
        cTimer = Timer.scheduledTimer(withTimeInterval: updateSpeed, repeats: true, block: { [weak self] t in
            guard let self = self else { return }
            self.captureScreen()
        })
    }
    
    func stopCapture() {
        isCapturing = false
        cTimer?.invalidate()
    }
    
    private func captureScreen() {
        let rect = selectedScreen.frame
        var cgRect: CGRect
        if rect.minX == 0, rect.minY == 0 {
            cgRect = rect
        } else {
            cgRect = CGRect(x: rect.minX, y: -rect.minY-rect.height, width: rect.width, height: rect.height)
        }
    
        let imageRef = CGWindowListCreateImage(cgRect, .optionAll, 0, .nominalResolution)

        previewImage = NSImage(cgImage: imageRef!, size: .zero)
        
        if let color = previewImage?.averageColor {
            setColor(color)
        }
    }
    
    // MARK: Down buttons actions
    
    private func createDownButtonActions() {
        downButtons = [
            .init(action: {[weak self] in self?.openGitHub()},
                  imageName: "GitHubIcon",
                  description: "Watch on GitHub"),
            .init(action: {[weak self] in self?.closeApp()},
                  imageName: "ExitIcon",
                  description: "Exit"),
            
        ]
    }
    
    private func closeApp() {
        NSRunningApplication.current.terminate()
    }
    
    private func openGitHub() {
        let url = URL(string: "https://github.com/John-Greenwood/YeelightMac")!
        NSWorkspace.shared.open(url)
    }
}
