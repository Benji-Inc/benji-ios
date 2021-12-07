//
//  ColorPickerWheelView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorWheelCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = CIColor

    var currentItem: CIColor?

    let colors: [CGColor] = [CGColor.init(_colorLiteralRed: 255,
                                          green: 0,
                                          blue: 0,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 255,
                                          green: 127,
                                          blue: 0,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 255,
                                          green: 255,
                                          blue: 0,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 0,
                                          green: 255,
                                          blue: 0,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 0,
                                          green: 0,
                                          blue: 255,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 46,
                                          green: 43,
                                          blue: 95,
                                          alpha: 1.0),
                             CGColor.init(_colorLiteralRed: 139,
                                          green: 0,
                                          blue: 255,
                                          alpha: 1.0)]

    lazy var gradientView = GradientView(with: self.colors, startPoint: .bottomLeft, endPoint: .topRight)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.gradientView)

        self.gradientView.layer.cornerRadius = 5
        self.gradientView.layer.borderWidth = 3
        self.gradientView.layer.borderColor = Color.clear.color.cgColor
        self.gradientView.layer.masksToBounds = true 
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.gradientView.squaredSize = self.height
    }

    func configure(with item: CIColor) {
        self.gradientView.layer.borderColor = CGColor.init(_colorLiteralRed: Float(item.red),
                                                           green: Float(item.green),
                                                           blue: Float(item.blue),
                                                           alpha: 1.0)
    }
}
