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
    
    let closeButton = ThemeButton()
    let closeImageView = UIImageView(image: UIImage(systemName: "xmark"))
    let imageView = UIImageView()
    let button = ThemeButton()
    let label = ThemeLabel(font: .medium, textColor: .white)
    let subTitle = ThemeLabel(font: .regular, textColor: .white)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .D1)
        self.roundCorners()
        
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.button)

        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.addSubview(self.subTitle)
        self.subTitle.alpha = 0.5
        self.subTitle.textAlignment = .center
        
        self.closeImageView.contentMode = .scaleAspectFit
        self.closeImageView.tintColor = ThemeColor.white.color
        self.closeImageView.alpha = 0.5
        
        self.addSubview(self.closeImageView)
        self.addSubview(self.closeButton)
    }
    
    func configure(with title: Localized,
                   subtitle: Localized,
                   image: UIImage?,
                   buttonTitle: Localized) {
        
        self.imageView.image = image
        self.button.set(style: .custom(color: .white, textColor: .D1, text: buttonTitle))
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
        
        self.imageView.squaredSize = 54
        self.imageView.match(.bottom, to: .top, of: self.label, offset: .negative(.xtraLong))
        self.imageView.centerOnX()
        
        self.subTitle.setSize(withWidth: self.width - padding)
        self.subTitle.centerOnX()
        self.subTitle.match(.top, to: .bottom, of: self.label, offset: .xtraLong)
        
        self.closeImageView.squaredSize = 20
        self.closeImageView.pin(.top, offset: .long)
        self.closeImageView.pin(.right, offset: .long)
        
        self.closeButton.squaredSize = 44
        self.closeButton.center = self.closeImageView.center
    }
}
