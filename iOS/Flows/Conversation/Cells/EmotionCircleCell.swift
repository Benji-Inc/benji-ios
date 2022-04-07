//
//  EmotionCircleCell.swift
//  Jibber
//
//  Created by Martin Young on 4/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionCircleCell: UICollectionViewCell {

    private let label = ThemeLabel(font: .regular, textColor: .white)

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
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.halfWidth

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }

    func configure(with emotion: Emotion) {
        self.label.text = emotion.rawValue
        self.backgroundColor = emotion.color.withAlphaComponent(0.7)

        self.setNeedsLayout()
    }
}
