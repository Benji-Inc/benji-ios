//
//  UpsellContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/2/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class UpsellContentView: BaseView {
    
    let button = ThemeButton()
    let label = ThemeLabel(font: .medium, textColor: .T3)
    let subTitle = ThemeLabel(font: .regular, textColor: .T3)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .D1)
        self.roundCorners()
        self.addSubview(self.button)

        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.addSubview(self.subTitle)
        self.subTitle.alpha = 0.5
        self.subTitle.textAlignment = .center
    }
    
    func configure(with title: Localized,
                   subtitle: Localized,
                   buttonTitle: Localized) {
        
        self.button.set(style: .custom(color: .white, textColor: .T2, text: buttonTitle))
        self.label.setText(title)
        self.subTitle.setText(subtitle)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let padding = Theme.ContentOffset.xtraLong.value.doubled
        
        self.button.height = Theme.buttonHeight
        self.button.width = self.width - padding
        self.button.centerOnX()
        self.button.pin(.bottom, offset: .xtraLong)
        
        self.label.setSize(withWidth: self.width - padding)
        self.label.centerOnX()
        self.label.center.y = self.halfHeight * 0.9
        
        self.subTitle.setSize(withWidth: self.width - padding)
        self.subTitle.centerOnX()
        self.subTitle.match(.top, to: .bottom, of: self.label, offset: .xtraLong)
    }
}
