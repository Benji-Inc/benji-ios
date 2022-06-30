//
//  EmotionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class AddExpressionView: BaseView {
        
    let addImageView = SymbolImageView(symbol: .plus)
    let imageView = SymbolImageView(symbol: .faceSmiling)
    let personGradientView = PersonGradientView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
        
        self.addSubview(self.addImageView)
        self.addImageView.tintColor = ThemeColor.whiteWithAlpha.color

        self.addSubview(self.personGradientView)
        self.personGradientView.isVisible = false
        
        self.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.personGradientView.expandToSuperviewSize()

        self.imageView.squaredSize = self.height
        self.imageView.centerOnXAndY()
        
        self.addImageView.squaredSize = self.imageView.height * 0.4
        self.addImageView.pin(.top, offset: .negative(.custom(self.addImageView.height * 0.2)))
        self.addImageView.match(.left, to: .right, of: self.imageView, offset: .negative(.custom(self.addImageView.height * 0.2)))
    }

    func configure(with info: ExpressionInfo?) {
        
        self.personGradientView.isVisible = info.exists
        
        self.addImageView.isVisible = info.isNil
        self.imageView.isVisible = info.isNil
        
        guard let info = info else { return }

        self.personGradientView.set(info: info, authorId: nil)
    }
    
    func configure(withExpression expression: Expression?) {
        
        self.personGradientView.isVisible = expression.exists
        
        self.addImageView.isVisible = expression.isNil
        self.imageView.isVisible = expression.isNil
        
        guard let expression = expression else { return }

        self.personGradientView.set(expression: expression, author: nil)
    }
}
