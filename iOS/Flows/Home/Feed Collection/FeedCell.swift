//
//  FeedCell.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = User

    var currentItem: User?

    private let avatarView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
    }

    func configure(with item: User) {

        item.retrieveDataIfNeeded()
            .mainSink(receivedResult: { result in
                switch result {
                case .success(let owner):
                    self.avatarView.set(avatar: owner)
                    self.avatarView.didDisplayImage = { [unowned self] image in
                        if item != User.current() {
                            self.checkForPosts(for: item, andUpdate: image)
                        }
                    }

                case .error(_):
                    break
                }
            }).store(in: &self.cancellables)
    }

    func checkForPosts(for user: User, andUpdate image: UIImage) {
        PostsSupplier.shared.getCountOfMediaPosts(for: user, excludeExpired: true)
            .mainSink { result in
                switch result {
                case .success(let count):
                    if count == 0 {
                        self.avatarView.imageView.image = image.grayscaleImage()
                    }
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    override func update(isSelected: Bool) {
        self.avatarView.borderColor = isSelected ? .purple : .background2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.height)
        self.avatarView.centerOnXAndY()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.avatarView.reset()
    }
}
