//
//  RoomNavigationButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RoomNavigationButton: BaseView {
    
    enum State {
        case outer
        case inner
    }
    
    let outerRoomView = BaseView()
    let innerRoomView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.outerRoomView)
        self.addSubview(self.innerRoomView)
        
        self.outerRoomView.layer.borderWidth = 2
        self.outerRoomView.layer.borderColor = ThemeColor.white.color.cgColor
        self.outerRoomView.layer.cornerRadius = 1
        
        self.innerRoomView.layer.borderWidth = 2
        self.innerRoomView.layer.borderColor = ThemeColor.white.color.cgColor
        self.innerRoomView.layer.cornerRadius = 1
    }
    
    func configure(for state: State) {
        
        switch state {
        case .outer:
            self.outerRoomView.layer.opacity = 1.0
            self.innerRoomView.layer.opacity = 0.3
        case .inner:
            self.outerRoomView.layer.opacity = 0.3
            self.innerRoomView.layer.opacity = 1.0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.squaredSize = 40
        
        self.outerRoomView.squaredSize = self.height - Theme.ContentOffset.long.value
        self.outerRoomView.centerOnXAndY()
        
        self.innerRoomView.squaredSize = self.outerRoomView.height - Theme.ContentOffset.long.value
        self.innerRoomView.centerOnXAndY()
    }
}
