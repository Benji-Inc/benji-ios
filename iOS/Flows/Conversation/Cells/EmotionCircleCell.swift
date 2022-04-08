//
//  EmotionCircleCell.swift
//  Jibber
//
//  Created by Martin Young on 4/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionCircleCell: UICollectionViewCell {

    private let label = ThemeLabel(font: .small, textColor: .white)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.clipsToBounds = true

        self.addSubview(self.label)
        self.contentView.layer.borderWidth = 2
        self.contentView.layer.masksToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.contentView.layer.cornerRadius = self.halfWidth

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }

    func configure(with emotion: Emotion) {
        self.label.text = emotion.rawValue
        
        self.label.textColor = emotion.color
        self.contentView.layer.borderColor = emotion.color.cgColor
        self.contentView.backgroundColor = emotion.color.withAlphaComponent(0.4)

        self.setNeedsLayout()
    }
}
