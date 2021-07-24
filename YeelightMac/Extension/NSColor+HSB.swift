//
//  NSColor+HSB.swift
//  YeelightMac
//
//  Created by John Greenwood on 19.05.2021.
//

import SwiftUI

extension NSColor {
    
    var HSB: (hue: Int, saturation: Int, brightness: Int) {
        var hue       : CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        
        self.getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: nil
        )
        
        return (Int(360 * hue), Int(100 * saturation), Int(100 * brightness))
    }
}
