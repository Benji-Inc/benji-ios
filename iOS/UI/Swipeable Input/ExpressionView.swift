//
//  EmotionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import StreamChat

class AddExpressionView: BaseView {
        
    let imageView = UIImageView(image: UIImage(systemName: "face.smiling"))
    let personGradientView = PersonGradientView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
        self.imageView.contentMode = .scaleAspectFit

        self.addSubview(self.personGradientView)
        
        self.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.personGradientView.expandToSuperviewSize()

        self.imageView.squaredSize = self.width * 0.8
        self.imageView.centerOnXAndY()
    }

    func configure(with expression: Expression?) {
        self.personGradientView.isVisible = expression.exists
        
        guard let expression = expression else {
            return
        }
        
        self.personGradientView.set(expression: expression)
    }
}
