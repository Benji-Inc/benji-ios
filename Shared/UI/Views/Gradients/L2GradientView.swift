//
//  L2GradientView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class L2GradientView: GradientView {
    
    private let gradientView = L4GradientView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        //self.set(backgroundColor: .L2)
        self.addSubview(self.gradientView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientView.expandToSuperviewSize()
    }
}
