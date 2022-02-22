//
//  ProfileHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileHeaderView: BaseView {
    
    let label = ThemeLabel(font: .regular)
    let avatarView = BorderedAvatarView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.addSubview(self.avatarView)
    }
    
    func configure(with avatar: Avatar) {
        self.avatarView.set(avatar: avatar)
        self.label.setText(avatar.fullName)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.pin(.top)
        self.label.centerOnX()
        
        self.avatarView.squaredSize = self.height * 0.6
        self.avatarView.centerOnXAndY()
    }
}
