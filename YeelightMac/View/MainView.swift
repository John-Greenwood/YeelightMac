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
    
    var body: some View {
        VStack {
            Picker(selection: $selectedDisplay, label: Text("🖥"), content: {
                ForEach(NSScreen.screens, id: \.self) { screen in
                    Text(screen.localizedName).tag(screen)
                }
            })
            .onReceive([self.selectedDisplay].publisher.first(), perform: { v in
                c.selectedScreen = v
            })
            
            VStack {
                HStack {
                    if let p = c.previewImage {
                        Image(nsImage: p)
                            .resizable()
                            .scaledToFit()
                        
                        if let color = p.averageColor {
                            Color(color)
                                .frame(width: 50, height: 50)
                        }
                        
                    } else {
                        Color.gray
                    }
                }
                .frame(height: 200)
                
                Button(c.isCapturing ? "Stop" : "Start") {
                    c.toggleCapture()
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 300, height: 200)
    }
}

class MainViewC: NSObject, ObservableObject {
    
    @Published var previewImage: NSImage?
    @Published var isCapturing = false
    
    var selectedScreen = NSScreen.screens.first!
    
    private var cTimer: Timer?
    
    
    
    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }
    
    private func startCapture() {
        isCapturing = true
        cTimer?.invalidate()
        cTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
            guard let self = self else { return }
            self.captureScreen()
        })
    }
    
    private func stopCapture() {
        isCapturing = false
        cTimer?.invalidate()
    }
    
    private func captureScreen() {
        let sRect = selectedScreen.frame
        let rect = NSRect(x: sRect.minX, y: -sRect.minY, width: sRect.width, height: sRect.height)
        let imageRef = CGWindowListCreateImage(rect, .optionAll, 0, .nominalResolution)
        previewImage = NSImage(cgImage: imageRef!, size: .zero)
    }
}
