//
//  NewChannelButton.swift
//  Benji
//
//  Created by Benji Dodgson on 12/26/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewChannelButton: LoadingButton {

    let iconImageView = UIImageView()
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)

    private var xOffset: CGFloat = 0
    private var yOffset: CGFloat = 0

    override var isEnabled: Bool {
        didSet {
            self.iconImageView.tintColor = self.isEnabled ? Color.white.color : Color.red.color.withAlphaComponent(0.4)
            self.isUserInteractionEnabled = self.isEnabled
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.iconImageView)
        self.iconImageView.tintColor = Color.white.color
        self.iconImageView.contentMode = .scaleAspectFit
        self.set(style: .normal(color: .purple, text: ""))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.makeRound()

        self.iconImageView.size = CGSize(width: self.width * 0.55, height: self.height * 0.55)
        self.iconImageView.centerX = self.halfWidth + self.xOffset
        self.iconImageView.centerY = self.halfHeight + self.yOffset
    }

    func update(for contentType: NewChannelContent) {
        UIView.animate(withDuration: Theme.animationDuration,
                       animations: {
                        self.iconImageView.alpha = 0
                        self.iconImageView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { (completed) in
            switch contentType {
            case .purpose(_):
                self.iconImageView.image = UIImage(systemName: "person.badge.plus")
                self.xOffset = -1
                self.yOffset = 0
            case .favorites(_):
                self.iconImageView.image = UIImage(systemName: "square.and.pencil")
                self.xOffset = 2
                self.yOffset = -2
            }

            self.layoutNow()

            UIView.animate(withDuration: Theme.animationDuration) {
                self.iconImageView.alpha = 1
                self.iconImageView.transform = .identity
            }
        }
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.selectionFeedback.impactOccurred()
    }
}
