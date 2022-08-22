//
//  ExpressionButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionButton: MomentButton {
    
    init() {
        super.init(with: .faceSmiling)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
