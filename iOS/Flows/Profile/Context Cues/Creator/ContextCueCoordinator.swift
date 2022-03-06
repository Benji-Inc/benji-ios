//
//  ContextCuesCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueCoordinator: PresentableCoordinator<Void> {
    
    lazy var creatorVC = ContextCueCreatorViewController()

    override func toPresentable() -> DismissableVC {
        return self.creatorVC
    }
}
