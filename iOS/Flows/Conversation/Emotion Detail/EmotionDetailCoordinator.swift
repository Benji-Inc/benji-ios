//
//  EmotionDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailCoordinator: PresentableCoordinator<Void> {

    private let emotions: [Emotion]
    private let startingEmotion: Emotion?
    private lazy var emotionDetailVC: EmotionDetailViewController = {
        return EmotionDetailViewController(emotions: self.emotions,
                                           startingEmotion: self.startingEmotion,
                                           delegate: self)
    }()

    override func toPresentable() -> DismissableVC {
        return self.emotionDetailVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         emotions: [Emotion],
         startingEmotion: Emotion?) {

        self.emotions = emotions
        self.startingEmotion = startingEmotion

        super.init(router: router, deepLink: deepLink)
    }
}

extension EmotionDetailCoordinator: EmotionDetailViewControllerDelegate {

    func emotionDetailViewControllerDidFinish(_ controller: EmotionDetailViewController) {
        self.finishFlow(with: ())
    }
}
