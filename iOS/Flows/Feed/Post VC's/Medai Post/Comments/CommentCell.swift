//
//  CommentsCell.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TMROLocalization

class CommentCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Comment

    private let avatarView = AvatarView()
    private let textView = CommentTextView()
    private let label = Label(font: .small, textColor: .background4)

    var currentItem: Comment?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.addSubview(self.avatarView)
        self.addSubview(self.textView)
    }

    func configure(with item: Comment) {
        if let author = item.author {
            author.retrieveDataIfNeeded()
                .mainSink { result in
                    switch result {
                    case .success(let user):
                        self.avatarView.set(avatar: user)
                    case .error(_):
                        break
                    }
                    self.layoutNow()
                }.store(in: &self.cancellables)
        }

        self.setText(comment: item)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

        let height: CGFloat = clamp(self.textView.bottom, min: 44)
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: height)
        return layoutAttributes
    }

    private func setText(comment: Comment) {
        guard let date = comment.createdAt else { return }
        self.label.setText(date.getDistanceAgoString())
        self.textView.set(text: String(optional: comment.body))
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: 44)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.pin(.top)

        let maxWidth = self.width - self.avatarView.right - Theme.contentOffset.doubled

        self.label.setSize(withWidth: maxWidth)
        self.label.match(.top, to: .top, of: self.avatarView)
        self.label.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)

        self.textView.setSize(withWidth: maxWidth)
        self.textView.match(.top, to: .bottom, of: self.label, offset: 8)
        self.textView.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.label.text = nil
        self.textView.text = nil 
    }
}
