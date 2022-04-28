//
//  ExpressionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCoordinator: PresentableCoordinator<URL?> {

    lazy var photoVC = ExpressionPhotoCaptureViewController()

    override func toPresentable() -> DismissableVC {
        return self.photoVC
    }
    
    override func start() {
        super.start()
        
        self.photoVC.onDidComplete = { [unowned self] _ in
            logDebug("did complete")
        }
    }
}
