//
//  UIColor+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

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
}
