//
//  CircleAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CircleAvatarView: BorderedPersonView {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.shadowLayer.opacity = 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.makeRound()
        self.pulseLayer.cornerRadius = self.halfHeight
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
