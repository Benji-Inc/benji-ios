//
//  UIColor+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {

    /// Returns a modified copy of this color with the specified brightness.
    /// A brightness of 1 leaves the color unchanged. 0.5 is a half as bright as the original color. 0 is black.
    func color(withBrightness brightness: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: red * brightness,
                           green: green * brightness,
                           blue: blue * brightness,
                           alpha: alpha)
        }

        return UIColor()
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}

func lerp(_ normalized: CGFloat, color1: UIColor, color2: UIColor) -> UIColor {
    var red1: CGFloat = 0
    var green1: CGFloat = 0
    var blue1: CGFloat = 0
    var alpha1: CGFloat = 0

    color1.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)

    var red2: CGFloat = 0
    var green2: CGFloat = 0
    var blue2: CGFloat = 0
    var alpha2: CGFloat = 0

    color2.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

    let newRed = (1.0 - normalized) * red1 + normalized * red2
    let newGreen = (1.0 - normalized) * green1 + normalized * green2
    let newBlue = (1.0 - normalized) * blue1 + normalized * blue2
    let newAlpha = (1.0 - normalized) * alpha1 + normalized * alpha2

    return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
}

extension CIColor {

    convenience init?(hex: String) {

        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }
}
