//
//  BenjiTheme.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

struct Theme {

    enum AnimationDuration: Double {
        case fast = 0.2
        case standard = 0.35
        case slow = 0.5
    }

    static let animationDurationFast: TimeInterval = 0.2
    static let animationDurationStandard: TimeInterval = 0.35
    static let animationDurationSlow: TimeInterval = 0.5
    static let cornerRadius: CGFloat = 10
    static let borderWidth: CGFloat = 2
    static let contentOffset: CGFloat = 24
    static let buttonHeight: CGFloat = 50
    static let iPadPortraitWidthRatio: CGFloat = 0.65
    static let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)

    private init() {}
}
