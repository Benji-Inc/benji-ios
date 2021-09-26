//
//  CircleCoordinator.swift
//  CircleCoordinator
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {

    private lazy var circleVC = CircleViewController(with: self.circleGroup)
    private let circleGroup: CircleGroup

    init(with group: CircleGroup,
         router: Router,
         deepLink: DeepLinkable?) {

        self.circleGroup = group
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.circleVC
    }

    override func start() {
        super.start()

    }
}
