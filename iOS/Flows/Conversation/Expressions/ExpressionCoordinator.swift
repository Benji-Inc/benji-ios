//
//  ExpressionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCoordinator: PresentableCoordinator<Expression?> {

    private lazy var photoVC = ExpressionPhotoCaptureViewController()

    override func toPresentable() -> DismissableVC {
        return self.photoVC
    }
    
    override func start() {
        super.start()
        
        self.photoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let expressionData):
                guard let expressionData = expressionData else {
                    self.finishFlow(with: nil)
                    break
                }
                let url = try? AttachmentsManager.shared.createTemporaryHeicURL(for: expressionData)
                self.finishFlow(with: Expression(imageURL: url, emojiString: nil))
            case .failure:
                break
            }
        }
    }
}
