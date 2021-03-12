//
//  GradientView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import QuartzCore

class GradientView: PassThroughView {

    private lazy var gradient = CAGradientLayer(start: self.start,
                                                end: self.end,
                                                colors: self.colors,
                                                type: .axial)
    private let colors: [CGColor]
    private let start: CAGradientLayer.Point
    private let end: CAGradientLayer.Point

    init(with colors: [CGColor],
         startPoint: CAGradientLayer.Point,
         endPoint: CAGradientLayer.Point) {

        self.colors = colors
        self.start = startPoint
        self.end = endPoint
        
        super.init()

        self.set(backgroundColor: .clear)

        self.layer.addSublayer(self.gradient)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.gradient.frame = self.bounds
    }
}
