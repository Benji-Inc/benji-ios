//
//  ReactionsDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class ReactionsDetailCoordinator: PresentableCoordinator<Void> {

    private let startingExpression: ExpressionInfo
    private let expressions: [ExpressionInfo]
    
    private lazy var detailVC: ReactionsDetailViewController = {
        return ReactionsDetailViewController(startingExpression: self.startingExpression,
                                              expressions: self.expressions,
                                              delegate: self)
    }()

    override func toPresentable() -> DismissableVC {
        return self.detailVC
    }

    init(router: CoordinatorRouter,
         deepLink: DeepLinkable?,
         startingExpression: ExpressionInfo,
         expressions: [ExpressionInfo]) {

        self.startingExpression = startingExpression
        self.expressions = expressions

        super.init(router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.detailVC.button.didSelect { [unowned self] in
            // add reaction
        }
    }
}

extension ReactionsDetailCoordinator: ExpressionDetailViewControllerDelegate {

    func emotionDetailViewControllerDidFinish(_ controller: ExpressionDetailViewController) {
        self.finishFlow(with: ())
    }
}
