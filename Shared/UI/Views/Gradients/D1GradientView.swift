//
//  D2GradientView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class D1GradientView: BaseView {
    
    private let gradientView = D4GradientView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .black)
        self.addSubview(self.gradientView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientView.expandToSuperviewSize()
    }
}

private class D4GradientView: GradientView {
    
    init() {
        let colors: [CGColor] = [UIColor(named: "D4_TOP_LEFT")!.cgColor,
                                 UIColor(named: "D4_BOTTOM_RIGHT")!.cgColor]
        super.init(with: colors,
                   startPoint: .topLeft,
                   endPoint: .bottomRight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}