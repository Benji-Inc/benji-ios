//
//  MomentButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ScrollCounter

class MomentButton: ThemeButton {
    
    var counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.smallBold.font,
                                      textColor: ThemeColor.white.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    private let symbol: ImageSymbol
    
    init(with symbol: ImageSymbol) {
        self.symbol = symbol
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.counter)
        
        let pointSize: CGFloat = 26
        
        self.set(style: .image(symbol: self.symbol,
                               palletteColors: [.white],
                               pointSize: pointSize,
                               backgroundColor: .clear))
        
        self.showShadow(withOffset: 0, opacity: 1.0)
        
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.counter.sizeToFit()
        self.counter.centerX = self.halfWidth - 1
        self.counter.top = self.height - 2
    }
}
