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

    var currentItem: Comment?

    func configure(with item: Comment) {
        var config = CommentContentConfiguration()
        config.comment = item
        self.contentConfiguration = config
    }
}

struct CommentContentConfiguration: UIContentConfiguration, Hashable {

    var comment: Comment?

    func makeContentView() -> UIView & UIContentView {
        return CommentContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

class CommentContentView: View, UIContentView {

    private let avatarView = AvatarView()
    private let textView = CommentTextView()
    private var cancellables = Set<AnyCancellable>()

    var configuration: UIContentConfiguration {
        get { self.appliedConfiguration }
        set {
            guard let newConfig = newValue as? CommentContentConfiguration else { return }
            self.apply(configuration: newConfig)
        }
    }

    private var appliedConfiguration: CommentContentConfiguration!

    init(configuration: CommentContentConfiguration) {
        super.init()
        self.apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.avatarView)
        self.addSubview(self.textView)
    }

    private func apply(configuration: CommentContentConfiguration) {
        guard self.appliedConfiguration != configuration else { return }
        self.appliedConfiguration = configuration

        if let author = configuration.comment?.author {
            author.retrieveDataIfNeeded()
                .mainSink { result in
                    switch result {
                    case .success(let user):
                        self.avatarView.set(avatar: user)
                    case .error(_):
                        break
                    }
                }.store(in: &self.cancellables)
        }

        self.textView.set(text: String(optional: configuration.comment?.body))
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.height)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.centerOnY()

        let width = self.width - self.avatarView.right - Theme.contentOffset
        self.textView.setSize(withWidth: width)
        self.textView.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
    }
}

class CommentTextView: TextView {

    override func initialize() {
        super.initialize()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true
    }

    func set(text: Localized) {
        let attributedString = AttributedString(text,
                                                fontType: .smallBold,
                                                color: .white)

        self.set(attributed: attributedString,
                 alignment: .left,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .teal)

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2

        self.addTextAttributes([NSAttributedString.Key.paragraphStyle: style])
    }

    // Allows us to interact with links if they exist or pass the touch to the next receiver if they do not
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // Find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // Check if character is a link and handle normally
            if (self.textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                return self
            }
        }

        // Return nil to pass touch to next receiver
        return nil
    }
}
