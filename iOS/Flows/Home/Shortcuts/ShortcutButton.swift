//
//  ShortcutButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutButton: ThemeButton, HomeStateHandler {

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.alpha = 0
        self.transform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)

        var shortcutConfig = UIImage.SymbolConfiguration(pointSize: 30)
        var shortcutHightlightConfig = UIImage.SymbolConfiguration(pointSize: 28)
        shortcutConfig = shortcutConfig.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        shortcutHightlightConfig = shortcutHightlightConfig.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        
        self.set(style: .image(symbol: .bolt,
                               palletteColors: [.white],
                               pointSize: 30,
                               backgroundColor: .D6))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.makeRound()
    }
    
    private var stateTask: Task<Void, Never>?

    func handleHome(state: HomeState) {
        self.stateTask?.cancel()
        
        self.stateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitSpringAnimation(with: .custom(1.0), animations: {
                switch state {
                case .initial:
                    self.transform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
                    self.alpha = 0
                case .tabs, .shortcuts:
                    self.transform = .identity
                    self.alpha = 1.0
                }
                
                self.setNeedsLayout()
            })
        }
    }
}
