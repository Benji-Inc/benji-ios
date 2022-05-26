//
//  ContextCuesCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class ContextCueCoordinator: PresentableCoordinator<Void> {
    
    lazy var creatorVC = ContextCueCreatorViewController()
    lazy var emojiNav = EmojiNavigationViewController(with: self.creatorVC)
    
    override init(router: CoordinatorRouter, deepLink: DeepLinkable?) {
        super.init(router: router, deepLink: deepLink)
        
        self.creatorVC.didCreateContextCue = { [unowned self] in
            self.finishFlow(with: ())
        }
    }

    override func toPresentable() -> DismissableVC {
        return self.emojiNav
    }
}
