//
//  CircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleView: BaseView {
    
    let avatarView = CircleAvatarView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        
        self.addSubview(self.avatarView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.expandToSuperviewSize()
    }
}
