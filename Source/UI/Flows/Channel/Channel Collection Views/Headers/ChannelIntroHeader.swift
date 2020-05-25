//
//  MessageIntroCell.swift
//  Benji
//
//  Created by Benji Dodgson on 5/25/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class ChannelIntroHeader: UICollectionReusableView {

    let avatarView = AvatarView()
    let textView = TextView()
    let label = DisplayLabel()

    private(set) var attributes: ChannelCollectionViewLayoutAttributes?
    private(set) var channel: DisplayableChannel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.addSubview(self.avatarView)
        self.addSubview(self.label)
        self.addSubview(self.textView)
        self.set(backgroundColor: .red)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attributes = layoutAttributes as? ChannelCollectionViewLayoutAttributes else { return }
        self.attributes = attributes
        self.layoutContent(with: attributes)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.attributes = nil
        self.textView.text = nil
    }

    func configure(with channel: DisplayableChannel) {
        self.channel = channel
    }

    private func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {

        self.avatarView.frame = attributes.attributes.avatarFrame
        self.textView.frame = attributes.attributes.textViewFrame
    }
}
