//
//  NewChannelCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewChannelCoordinator: PresentableCoordinator<Void> {

    lazy var newChannelVC = NewChannelViewController()

    override func toPresentable() -> DismissableVC {
        return self.newChannelVC
    }

    override func start() {
        super.start()

        self.newChannelVC.didCreateChannel = { [unowned self] in 
            self.finishFlow(with: ())
        }
    }
}
