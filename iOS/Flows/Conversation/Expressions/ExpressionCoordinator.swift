//
//  ExpressionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class ExpressionCoordinator: PresentableCoordinator<Expression?> {

    private lazy var expressionVC = ExpressionViewController()

    override func toPresentable() -> DismissableVC {
        return self.expressionVC
    }
    
    override func start() {
        super.start()
        
        self.expressionVC.didCompleteExpression = { [unowned self] expression in
            self.finishFlow(with: expression)
        }
    }
}
