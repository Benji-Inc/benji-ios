//
//  HomeTabView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeTabView: View {

    private(set) var postButtonView = PostButtonView()
    private(set) var profileItem = ImageViewButton()
    private(set) var channelsItem = ImageViewButton()

    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    private var indicatorCenterX: CGFloat?

    var currentContent: HomeContent?
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.profileItem)
        self.addSubview(self.postButtonView)
        self.addSubview(self.channelsItem)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let topPadding: CGFloat = 20

        let itemWidth = self.width * 0.33
        let itemSize = CGSize(width: itemWidth, height: 60)
        self.profileItem.size = itemSize
        self.profileItem.pin(.top, padding: topPadding)
        self.profileItem.left = 0

        self.postButtonView.size = itemSize
        self.postButtonView.pin(.top)
        self.postButtonView.left = self.profileItem.right

        self.channelsItem.size = itemSize
        self.channelsItem.pin(.top, padding: topPadding)
        self.channelsItem.left = self.postButtonView.right
    }

    func updateTabItems(for contentType: HomeContent) {
        self.selectionFeedback.impactOccurred()
        self.currentContent = contentType
        self.updateButtons(for: contentType)
    }

    private func updateButtons(for contentType: HomeContent) {
        switch contentType {
        case .feed:
            self.profileItem.imageView.image = UIImage(systemName: "person.crop.circle")
            self.profileItem.imageView.tintColor = Color.background3.color
            self.channelsItem.imageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
            self.channelsItem.imageView.tintColor = Color.background3.color
        case .channels:
            self.profileItem.imageView.image = UIImage(systemName: "person.crop.circle")
            self.profileItem.imageView.tintColor = Color.background3.color
            self.channelsItem.imageView.image = UIImage(systemName: "bubble.left.and.bubble.right.fill")
            self.channelsItem.imageView.tintColor = Color.purple.color
        case .profile:
            self.profileItem.imageView.image = UIImage(systemName: "person.crop.circle.fill")
            self.profileItem.imageView.tintColor = Color.purple.color
            self.channelsItem.imageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
            self.channelsItem.imageView.tintColor = Color.background3.color
        }
    }
}
