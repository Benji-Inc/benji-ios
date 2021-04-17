//
//  StackedAvatarView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/6/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class StackedAvatarView: View {

    private var imageViews: [AvatarView] = []
    private let maxItems: Int = 3
    private(set) var defaultHeight: CGFloat = 60

    var itemHeight: CGFloat = 60 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var offsetMultiplier: CGFloat = 0.5 {
        didSet {
            self.setNeedsLayout()
        }
    }

    func set(items: [Avatar]) {
        self.imageViews.removeAllFromSuperview(andRemoveAll: true)

        let max: Int = min(items.count, self.maxItems)
        for index in stride(from: max - 1, through: 0, by: -1) {
            let item: Avatar = items[index]
            let avatarView = AvatarView()
            avatarView.set(avatar: item)
            avatarView.imageView.layer.borderColor = Color.white.color.cgColor
            avatarView.imageView.layer.borderWidth = 2

            self.imageViews.append(avatarView, toSuperview: self)
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.setSize()
        for (index, imageView) in self.imageViews.enumerated() {
            let size = imageView.getSize(for: self.itemHeight)
            let offset = CGFloat(index) * size.width * self.offsetMultiplier
            imageView.alpha = alpha
            imageView.size = size
            imageView.right = self.width - offset
            imageView.centerOnY()
        }
    }

    func setSize() {
        var totalWidth: CGFloat = 0

        var size: CGSize = .zero
        for (index, imageView) in self.imageViews.enumerated() {
            size = imageView.getSize(for: self.itemHeight)
            let offset = CGFloat(index) * size.width * self.offsetMultiplier
            totalWidth += offset
        }

        if totalWidth == 0 {
            totalWidth += size.width
        } else {
            totalWidth += size.width * self.offsetMultiplier
        }
        
        self.size = CGSize(width: totalWidth, height: self.itemHeight)
    }

    func reset() {
        self.imageViews = []
        self.setSize()
    }
}

