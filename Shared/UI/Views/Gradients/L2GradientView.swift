//
//  L2GradientView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class L2GradientView: GradientView {
    
    init() {
        let colors: [CGColor] = [UIColor(named: "BG_TOP_LEFT")!.cgColor,
                                 UIColor(named: "BG_BOTTOM_RIGHT")!.cgColor]
        super.init(with: colors,
                   startPoint: .topLeft,
                   endPoint: .bottomRight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
