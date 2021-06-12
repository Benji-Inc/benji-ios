//
//  ChannelsGradientView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelsGradientView: GradientView {

    init() {
        let colors: [CGColor] = [Color.background1.color.cgColor,
                                 Color.background1.color.cgColor,
                                 Color.background1.color.withAlphaComponent(0.9).cgColor,
                                 Color.background1.color.withAlphaComponent(0.8).cgColor,
                                 Color.background1.color.withAlphaComponent(0.6).cgColor,
                                 Color.background1.color.withAlphaComponent(0).cgColor].reversed()
        
        super.init(with: colors, startPoint: .topCenter, endPoint: .bottomCenter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
