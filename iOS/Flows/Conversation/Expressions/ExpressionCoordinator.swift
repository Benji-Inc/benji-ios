//
//  ExpressionCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCoordinator: PresentableCoordinator<Emoji> {
    
    lazy var expressionVC = ExpressionViewController()
    lazy var emojiNav = EmojiNavigationViewController(with: self.expressionVC)

    override func toPresentable() -> DismissableVC {
        return self.emojiNav
    }
    
    override func start() {
        super.start()
        
        self.expressionVC.$selectedEmojis.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            self.finishFlow(with: first)
        }.store(in: &self.cancellables)
    }
}
