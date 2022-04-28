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

class ExpressionView: BaseView {
        
    let imageView = UIImageView(image: UIImage(systemName: "face.smiling"))
    let expressionImageView = DisplayableImageView()
    let label = ThemeLabel(font: .contextCues)
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
        self.imageView.contentMode = .scaleAspectFit

        self.addSubview(self.expressionImageView)

        self.addSubview(self.label)
        
        self.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()

        self.expressionImageView.expandToSuperviewSize()

        self.imageView.squaredSize = self.width * 0.8
        self.imageView.centerOnXAndY()
    }

    func configure(with expression: Expression?) {
        self.expressionImageView.displayable = expression?.imageURL
        self.expressionImageView.isVisible = expression?.imageURL != nil
        self.configure(forEmojiString: expression?.emojiString)
    }

    private func configure(forEmojiString string: String?) {
        if let e = string {
            self.label.setText(e)
            self.label.isVisible = true
            self.imageView.isVisible = false
        } else {
            self.label.isVisible = false
            self.imageView.isVisible = true
        }

        self.setNeedsLayout()
    }
}
