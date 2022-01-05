//
//  L5GradientView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class L5GradientView: GradientView {
    
    init() {
        let colors: [CGColor] = [UIColor(named: "L5_TOP")!.cgColor,
                                 UIColor(named: "L5_BOTTOM")!.cgColor]
        super.init(with: colors,
                   startPoint: .topCenter,
                   endPoint: .bottomCenter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
