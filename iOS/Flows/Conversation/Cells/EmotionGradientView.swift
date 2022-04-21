//
//  EmotionGradientView.swift
//  Jibber
//
//  Created by Martin Young on 4/13/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class EmotionGradientView: BaseView {

    private var gradientLayer = CAGradientLayer()

    init(emotionCounts: [Emotion : Int] = [:]) {
        super.init()

        self.set(emotionCounts: emotionCounts)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.clipsToBounds = true
        self.layer.borderWidth = 2
        self.layer.masksToBounds = true

        self.gradientLayer.type = .radial
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        self.layer.addSublayer(self.gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.halfWidth

        self.gradientLayer.frame = self.bounds
    }

    func set(emotionCounts: [Emotion : Int]) {
        var emotions: [Emotion] = []
        for emotionCount in emotionCounts {
            for _ in 0..<emotionCount.value {
                emotions.append(emotionCount.key)
            }
        }
        // Sort the colors by hue so more similar colors are near each other.
        emotions = emotions.sorted()

        var colors: [UIColor] = emotions.map { emotion in
            return emotion.color
        }

        if colors.isEmpty {
            colors = [ThemeColor.B0.color, ThemeColor.B1.color]
        }

        if let firstColor = colors.first {
            colors.insert(firstColor.color(withBrightness: 0.75), at: 0)
        }

        let cgColors = colors.map({ color in
            return color.cgColor
        })

        self.gradientLayer.colors = cgColors
        self.layer.borderColor = cgColors.last
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Ensure that the tap area is big enough to be usable as a button.
        let horizontalAdjustment = clamp(44 - self.bounds.width, min: 0)
        let verticalAdjustment = clamp(44 - self.bounds.height, min: 0)
        let extendedBounds = CGRect(x: self.bounds.x - horizontalAdjustment.half,
                                    y: self.bounds.y - horizontalAdjustment.half,
                                    width: self.bounds.width + horizontalAdjustment,
                                    height: self.bounds.height + verticalAdjustment)

        return extendedBounds.contains(point)
    }
}
