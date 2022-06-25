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
    
    var gradientLayer = GradientLayer.init(with: [],
                                           startPoint: .topLeft,
                                           endPoint: .bottomRight)
    
    var defaultColors: [ThemeColor] = [.B0, .B6]
    
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
        self.layer.addSublayer(self.gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.height * 0.25
        
        self.gradientLayer.frame = self.bounds
    }
    
    @discardableResult
    func set(emotionCounts: [Emotion : Int]) -> [UIColor] {
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
            colors = self.defaultColors.compactMap({ themeColor in
                return themeColor.color
            })
        }
        
        if let firstColor = colors.first {
            colors.insert(firstColor.color(withBrightness: 0.75), at: 0)
        }
        
        let cgColors = colors.map({ color in
            return color.cgColor
        })
        
        self.gradientLayer.updateCGColors(with: cgColors)
        
        return colors
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
