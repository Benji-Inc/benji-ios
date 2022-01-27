//
//  CircleAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CircleAvatarView: BorderedAvatarView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.makeRound()
                        
        self.pulseLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
