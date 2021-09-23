//
//  UITextField+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension UITextField {

    func setDefaultAttributes(style: StringStyle, alignment: NSTextAlignment = .left) {
        //APPLE BUG: Trying to set defaultAttributes will cause a memory crash
        self.font = style.fontType.font
        self.textColor = style.color.color
        self.textAlignment = alignment
    }

    func setPlaceholder(attributed: AttributedString, alignment: NSTextAlignment = .left) {
        self.attributedPlaceholder = attributed.string
        self.textAlignment = alignment
    }
}
