//
//  DownButtonV.swift
//  YeelightMac
//
//  Created by John Greenwood on 24.07.2021.
//

import SwiftUI

struct DownButtonModel: Identifiable {
    var id          = UUID.init()
    var action      = {}
    var imageName   = "ExitIcon"
    var description = "Description"
}

struct DownButtonV: View {
    @State var model: DownButtonModel
    
    var body: some View {
        Button(action: model.action) {
            VStack {
                Image(nsImage: .init(named: model.imageName) ?? .init())
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .help(model.description)
        .buttonStyle(PlainButtonStyle())
    }
}

struct DownButtonV_Previews: PreviewProvider {
    static var previews: some View {
        DownButtonV(model: .init())
    }
}
