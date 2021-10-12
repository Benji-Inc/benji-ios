//
//  MessageCell.swift
//  MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageCell: UICollectionViewCell {

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let cellRegistration = UICollectionView.CellRegistration<MessageSubcell, Messageable>
    { (cell, indexPath, item) in
        cell.setText(with: item)
    }

    private var message: Messageable?
    private var replies: [Messageable] = []
    /// The total number of replies to the root message. This may be more than the number of replies passed in.
    private var totalReplyCount: Int = 0
    /// The maximum number of replies we'll show.
    private let maxShownReplies = 2

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionView.isUserInteractionEnabled = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.set(backgroundColor: .clear)
        self.contentView.addSubview(self.collectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    /// Configures the cell to display the given messages.
    ///
    /// - Parameters:
    ///     - message: The root message to display, which may have replies.
    ///     - replies: The currently loaded replies to the message. These should be order by newest to oldest.
    ///     - totalReplyCount: The total number of replies that this message has. It may be more than the passed in replies.
    func set(message: Messageable, replies: [Messageable], totalReplyCount: Int) {
        self.message = message
        self.replies = replies.prefix(self.maxShownReplies).reversed()
        self.totalReplyCount = totalReplyCount

        self.collectionView.reloadData()
    }
}

extension MessageCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one to account for the base message.
        return self.replies.count + 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let message: Messageable?
        // The first item is always the base message.
        if indexPath.item == 0 {
            message = self.message
        } else {
            message = self.replies[safe: indexPath.item - 1]
        }

        guard let message = message else { return UICollectionViewCell() }

        let cell = collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration,
                                                                for: indexPath,
                                                                item: message)

        let totalCells = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)

        let stackIndex = totalCells - indexPath.item - 1
        cell.configureBackground(withStackIndex: stackIndex, message: message)

        // Only show the reply count on the top cell in the stack, and only if there is more than one reply.
        if stackIndex == 0 && self.totalReplyCount > 1 {
            cell.setReplyCount(self.totalReplyCount)
        } else {
            cell.setReplyCount(nil)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.width
        let height = collectionView.height - 40

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        // Return a negative spacing so that the cells overlap.
        return -collectionView.height + 60
    }
}

/// A cell for displaying individual the root message and replies within the MessageCell.
private class MessageSubcell: UICollectionViewCell {

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = UIView()
    /// Text view for displaying the text of the message.
    let textView = TextView()
    /// A label to show the total number of replies for the root message.
    let replyCountLabel = Label(font: .small)

    /// Where this cell appears on the z-axis stack of messages. 0 means the item closest to the user.
    private var stackIndex = 0
    /// How much to scale the size of the background view.
    private var scaleFactor: CGFloat {
        return 1 - CGFloat(self.stackIndex) * 0.05
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.intitializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.intitializeViews()
    }

    private func intitializeViews() {
        self.contentView.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)
        self.textView.isScrollEnabled = false
        self.textView.isEditable = false

        self.backgroundColorView.addSubview(self.replyCountLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.width = self.width * self.scaleFactor
        self.backgroundColorView.expandToSuperviewHeight()
        self.backgroundColorView.centerOnXAndY()

        self.textView.expandToSuperviewWidth()
        self.textView.sizeToFit()
        self.textView.centerOnXAndY()

        self.replyCountLabel.sizeToFit()
        self.replyCountLabel.pin(.right,padding: 8)
        self.replyCountLabel.pin(.top, padding: 8)
    }

    func setText(with message: Messageable) {
        self.textView.text = message.kind.text
        self.setNeedsLayout()
    }

    func configureBackground(withStackIndex stackIndex: Int, message: Messageable) {
        // How much to scale the brightness of the background view.
        let colorFactor = 1 - CGFloat(stackIndex) * 0.05

        var backgroundColor: UIColor
        if message.isFromCurrentUser {
            backgroundColor = Color.lightPurple.color
        } else {
            backgroundColor = Color.orange.color
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            backgroundColor = UIColor(red: red * colorFactor,
                                      green: green * colorFactor,
                                      blue: blue * colorFactor,
                                      alpha: alpha)
        }

        self.backgroundColorView.backgroundColor = backgroundColor

        self.stackIndex = stackIndex
        self.setNeedsLayout()
    }

    func setReplyCount(_ count: Int?) {
        guard let count = count else {
            self.replyCountLabel.text = nil
            return
        }

        self.replyCountLabel.setText("\(count) replies")
        self.setNeedsLayout()
    }
}
