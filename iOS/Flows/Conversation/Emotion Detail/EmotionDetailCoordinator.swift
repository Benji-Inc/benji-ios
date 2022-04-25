//
//  EmotionDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailCoordinator: PresentableCoordinator<Void> {

    #warning("Fix this")
    private lazy var emotionDetailVC = EmotionDetailViewController(emotions: [.afraid, .bored, .calm, .dread],
                                                                   startingEmotion: .calm)

    override func toPresentable() -> DismissableVC {
        return self.emotionDetailVC
    }
}
