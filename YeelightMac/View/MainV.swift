//
//  MainView.swift
//  YeelightMac
//
//  Created by John Greenwood on 18.05.2021.
//

import SwiftUI

struct MainV: View {
    
    @ObservedObject var c = MainC()
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
        .frame(width: 300, height: 400)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainV()
    }
}
