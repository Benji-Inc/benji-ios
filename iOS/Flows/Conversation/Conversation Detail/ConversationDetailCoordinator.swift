//
//  ConversationDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ConversationDetailCoordinator: PresentableCoordinator<Void> {
    
    lazy var detailVC = ConversationDetailViewController()

    override func toPresentable() -> DismissableVC {
        return self.detailVC
    }
    
    override func start() {
        super.start()
                
    }
}
