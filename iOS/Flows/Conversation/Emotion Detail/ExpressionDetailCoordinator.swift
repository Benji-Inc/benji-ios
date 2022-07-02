//
//  EmotionDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class ExpressionDetailCoordinator: PresentableCoordinator<Void> {

    private let startingExpression: ExpressionInfo
    private let expressions: [ExpressionInfo]
    
    private lazy var emotionDetailVC: ExpressionDetailViewController = {
        return ExpressionDetailViewController(startingExpression: self.startingExpression,
                                              expressions: self.expressions,
                                              delegate: self)
    }()

    override func toPresentable() -> DismissableVC {
        return self.emotionDetailVC
    }

    init(router: CoordinatorRouter,
         deepLink: DeepLinkable?,
         startingExpression: ExpressionInfo,
         expressions: [ExpressionInfo]) {

        self.startingExpression = startingExpression
        self.expressions = expressions

        super.init(router: router, deepLink: deepLink)
    }
}

extension ExpressionDetailCoordinator: ExpressionDetailViewControllerDelegate {

    func emotionDetailViewControllerDidFinish(_ controller: ExpressionDetailViewController) {
        self.finishFlow(with: ())
    }
}
