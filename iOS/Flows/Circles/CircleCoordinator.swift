//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {

    lazy var circleVC = CircleViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.circleVC
    }

    override func start() {
        super.start()

       
    }
}
