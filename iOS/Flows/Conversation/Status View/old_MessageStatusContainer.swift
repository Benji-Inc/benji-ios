//
//  MessageStatusContainer.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class old_MessageStatusContainer: BaseView {

    let maxWidth: CGFloat = 200
    let minWidth: CGFloat = 25
    let padding = Theme.ContentOffset.standard

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.D6withAlpha.color.cgColor
        self.layer.borderWidth = 0.5

        self.clipsToBounds = true
    }
}
