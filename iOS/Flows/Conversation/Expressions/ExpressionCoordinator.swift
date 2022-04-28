//
//  ExpressionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCoordinator: PresentableCoordinator<Expression?> {

    lazy var photoVC = ExpressionPhotoCaptureViewController()

    override func toPresentable() -> DismissableVC {
        return self.photoVC
    }
    
    override func start() {
        super.start()
        
        self.photoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let expressionImage):
                guard let expressionImage = expressionImage else {
                    self.finishFlow(with: nil)
                    break
                }
                let url = try? AttachmentsManager.shared.createTemporaryPngURL(for: expressionImage)
                self.finishFlow(with: Expression(imageURL: url, emoji: nil))
            case .failure:
                break
            }
        }
    }
}
