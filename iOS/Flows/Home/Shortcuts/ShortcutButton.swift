//
//  ShortcutButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutButton: ThemeButton {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
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
}
