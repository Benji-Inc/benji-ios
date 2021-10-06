//
//  MessageCell.swift
//  MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageCell: UICollectionViewCell {

    private let messageContainerView = UIView()
    private let messageTextView = TextView()

    private let repliesContainerView = UIView()
    private let replyCountLabel = Label(font: .regular)
    private let repliesTextView = TextView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.messageContainerView)
        self.messageContainerView.set(backgroundColor: .lightPurple)

        self.messageContainerView.addSubview(self.messageTextView)
        self.messageTextView.isScrollEnabled = false
        self.messageTextView.isEditable = false

        self.contentView.addSubview(self.repliesContainerView)
        self.repliesContainerView.set(backgroundColor: .lightPurple)

        self.repliesContainerView.addSubview(self.replyCountLabel)
        self.repliesContainerView.addSubview(self.repliesTextView)
        self.repliesTextView.isScrollEnabled = false
        self.repliesTextView.isEditable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.messageContainerView.expandToSuperviewWidth()
        self.messageContainerView.expand(.bottom, padding: 20)
        self.messageContainerView.roundCorners()
        self.messageContainerView.alpha = self.repliesContainerView.isVisible ? 0.8 : 1

        self.messageTextView.expandToSuperviewWidth()
        self.messageTextView.sizeToFit()
        self.messageTextView.centerOnXAndY()

        self.repliesContainerView.expandToSuperviewWidth()
        self.repliesContainerView.top = 10
        self.repliesContainerView.expand(.bottom)
        self.repliesContainerView.roundCorners()

        self.replyCountLabel.setSize(withWidth: self.repliesContainerView.width)
        self.replyCountLabel.pin(.right)
        self.replyCountLabel.pin(.top)

        self.repliesTextView.expandToSuperviewWidth()
        self.repliesTextView.sizeToFit()
        self.repliesTextView.centerOnXAndY()
    }

    func setMessage(_ text: String) {
        self.messageTextView.text = text

        self.setNeedsLayout()
    }

    func setReplyCount(_ count: Int) {
        self.replyCountLabel.setText("\(count)")
    }
    
    func setReplies(_ replies: [String]) {
        guard let latestReply = replies.first else {
            self.repliesTextView.text = nil
            self.repliesContainerView.isHidden = true
            return
        }


        self.repliesTextView.text = latestReply
        self.repliesContainerView.isHidden = false

        self.setNeedsLayout()
    }


    func setIsDeleted() {
        self.messageTextView.text = "DELETED"
        self.repliesContainerView.isHidden = true

        self.setNeedsLayout()
    }
}
