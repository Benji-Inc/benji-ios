//
//  EmotionDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailCoordinator: PresentableCoordinator<Void> {

    private let emotionDetailVC: EmotionDetailViewController

    override func toPresentable() -> DismissableVC {
        return self.emotionDetailVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         emotions: [Emotion],
         startingEmotion: Emotion?) {

        self.emotionDetailVC = EmotionDetailViewController(emotions: emotions,
                                                           startingEmotion: startingEmotion)
        super.init(router: router, deepLink: deepLink)
    }
}
