//
//  CommentContentView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CommentContentView: View, UIContentView {

    private let avatarView = AvatarView()
    private let textView = CommentTextView()
    private let label = Label(font: .small, textColor: .background4)
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

        self.addSubview(self.label)
        self.addSubview(self.avatarView)
        self.addSubview(self.textView)
    }

    private func apply(configuration: CommentContentConfiguration) {
        guard self.appliedConfiguration != configuration, let comment = configuration.comment else { return }
        self.appliedConfiguration = configuration

        if let author = comment.author {
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

        self.setText(comment: comment)
    }

    private func setText(comment: Comment) {
        guard let date = comment.createdAt else { return }
        self.label.setText(date.getDistanceAgoString())
        self.textView.set(text: String(optional: comment.body))
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.height)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.centerOnY()

        let maxWidth = self.width - self.avatarView.right - Theme.contentOffset.doubled

        self.label.setSize(withWidth: maxWidth)
        self.label.match(.top, to: .top, of: self.avatarView)
        self.label.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)

        self.textView.setSize(withWidth: maxWidth)
        self.textView.match(.top, to: .bottom, of: self.label, offset: 8)
        self.textView.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
    }
}
