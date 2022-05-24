//
//  NoticeDetailContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeDetailContentView: NoticeContentView {
    
    let titleLabel = ThemeLabel(font: .mediumBold, textColor: .white)
    let descriptionLabel = ThemeLabel(font: .regular, textColor: .white)
    let imageView = BorderedPersonView()
    let rightButtonLabel = ThemeLabel(font: .regularBold)
    let leftButtonLabel = ThemeLabel(font: .regular)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B6)
        
        self.addSubview(self.imageView)
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        
        self.addSubview(self.rightButtonLabel)
        self.rightButtonLabel.isUserInteractionEnabled = true
        self.rightButtonLabel.didSelect { [unowned self] in
            self.didSelectPrimaryOption?()
        }
        
        self.addSubview(self.leftButtonLabel)
        self.leftButtonLabel.isUserInteractionEnabled = true
        self.leftButtonLabel.didSelect { [unowned self] in
            self.didSelectSecondaryOption?()
        }
        self.leftButtonLabel.alpha = 0.25
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.xtraLong
        
        self.imageView.setSize(forHeight: 38)
        self.imageView.pin(.left, offset: padding)
        self.imageView.pin(.top, offset: padding)
        
        var maxTitleWidth = self.width - (self.imageView.right + padding.value.doubled)
        if self.imageView.displayable.isNil {
            maxTitleWidth = self.width - padding.value.doubled
        }
        
        self.titleLabel.setSize(withWidth: maxTitleWidth)
        if self.imageView.displayable.isNil {
            self.titleLabel.pin(.left, offset: padding)
        } else {
            self.titleLabel.match(.left, to: .right, of: self.imageView, offset: padding)
        }
        self.titleLabel.match(.top, to: .top, of: self.imageView)
        
        self.descriptionLabel.setSize(withWidth: maxTitleWidth)
        self.descriptionLabel.match(.left, to: .left, of: self.titleLabel)
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
        
        self.rightButtonLabel.setSize(withWidth: self.width)
        self.rightButtonLabel.pin(.right, offset: padding)
        self.rightButtonLabel.pin(.bottom, offset: padding)
        
        self.leftButtonLabel.setSize(withWidth: self.width)
        self.leftButtonLabel.match(.right, to: .left, of: self.rightButtonLabel, offset: .negative(.xtraLong))
        self.leftButtonLabel.pin(.bottom, offset: padding)
    }
}
