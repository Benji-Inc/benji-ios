//
//  PlaceholderMessageCell.swift
//  Jibber
//
//  Created by Martin Young on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PlaceholderMessageCell: UICollectionViewCell {

    let gradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight], startPoint: .topLeft, endPoint: .bottomRight)
    let containerView = BaseView()
    let dropZoneView = MessageDropZoneView()

    private var animationTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        
        self.gradientLayer.opacity = 0.2
        self.containerView.layer.insertSublayer(self.gradientLayer, at: 1)
        
        self.contentView.addSubview(self.containerView)
        self.containerView.addSubview(self.dropZoneView)
        self.dropZoneView.setState(.newMessage, messageColor: .D1)

        self.animationTask = Task {
            await self.animateInDropZone()
        }
        
        self.containerView.layer.cornerRadius = Theme.cornerRadius
        self.containerView.clipsToBounds = true
        
        self.containerView.set(backgroundColor: .L1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.containerView.expandToSuperviewWidth()
        self.containerView.height = MessageContentView.bubbleHeight - Theme.ContentOffset.short.value
        
        self.dropZoneView.height = self.containerView.height - Theme.ContentOffset.long.value
        self.dropZoneView.width = self.containerView.width - Theme.ContentOffset.long.value
        
        self.dropZoneView.centerOnXAndY()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.containerView.bounds
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.containerView.alpha = 0

        self.animationTask?.cancel()
        self.animationTask = Task {
            await self.animateInDropZone()
        }
    }

    @MainActor
    private func animateInDropZone() async {
        await Task.sleep(seconds: Theme.animationDurationStandard)

        guard !Task.isCancelled else { return }

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.containerView.alpha = 1
        }
    }
}
