//
//  EmotionDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailCoordinator: PresentableCoordinator<Void> {

    private let expression: Expression
    private let startingEmotion: Emotion?
    private lazy var emotionDetailVC: EmotionDetailViewController = {
        return EmotionDetailViewController(expression: self.expression,
                                           startingEmotion: self.startingEmotion,
                                           delegate: self)
    }()

    override func toPresentable() -> DismissableVC {
        return self.emotionDetailVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         expression: Expression,
         startingEmotion: Emotion?) {

        self.expression = expression
        self.startingEmotion = startingEmotion

        super.init(router: router, deepLink: deepLink)
    }
}

extension EmotionDetailCoordinator: EmotionDetailViewControllerDelegate {

    func emotionDetailViewControllerDidFinish(_ controller: EmotionDetailViewController) {
        self.finishFlow(with: ())
    }
}
