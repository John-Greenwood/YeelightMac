//
//  MainView.swift
//  YeelightMac
//
//  Created by John Greenwood on 18.05.2021.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var c = MainViewC()
    @State var selectedDisplay = NSScreen.screens.first!
    @State var ambientLightStarted = false
    @State var power = true
    
    var body: some View {
        VStack {
            Group {
                Picker(selection: $selectedDisplay, label: Text("🖥"), content: {
                    ForEach(NSScreen.screens, id: \.self) { screen in
                        Text(screen.localizedName).tag(screen)
                    }
                })
                .onReceive([self.selectedDisplay].publisher.first(), perform: { v in
                    c.selectedScreen = v
                })
            }
            
            Divider()
            
            Group {
                HStack {
                    Text("💡 \( c.connectionText)")
                    Spacer()
                    Toggle(isOn: $power, label: {})
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: power, perform: { on in
                            c.power(on)
                        })
                }
            }
            
            Divider()
            
            Group {
                HStack {
                    Text("Ambient light")
                        .font(.title2)
                    Spacer()
                    Toggle(isOn: $ambientLightStarted, label: {})
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: ambientLightStarted, perform: { s in
                            s ? c.startCapture() : c.stopCapture()
                        })
                }
                
                    
                HStack(alignment: .top) {
                    Image(nsImage: c.previewImage ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 100)
                    
                    Color(c.previewImage?.averageColor ?? .white)
                        .frame(width: 50, height: 50)
                    
                    Text("H: \(c.previewImage?.averageColor?.HSB.hue ?? 0)\nS: \(c.previewImage?.averageColor?.HSB.saturation ?? 0)\nB: \(c.previewImage?.averageColor?.HSB.brightness ?? 0)")
                }
                .frame(height: 100)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 500)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 300, height: 500)
    }
}

class MainViewC: NSObject, ObservableObject {
    
    @Published var previewImage: NSImage?
    @Published var isCapturing = false
    
    var selectedScreen = NSScreen.screens.first!
    var updateSpeed: TimeInterval = 0.5
    var diffSense = 10
    
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
}
