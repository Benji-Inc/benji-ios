//
//  MessageCell.swift
//  MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageCell: UICollectionViewCell {

    private let replyCountLabel = Label(font: .regular)

    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
    private let cellRegistration = UICollectionView.CellRegistration<TextViewCell, Messageable>
    { (cell, indexPath, item) in
        cell.setText(with: item)
    }

    private var message: Messageable?
    private var replies: [Messageable] = []
    private let maxShownReplies = 2

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.layout.scrollDirection = .vertical
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    func setMessage(_ message: Messageable) {
        self.message = message
        self.collectionView.reloadData()
    }

    func setReplies(_ replies: [Messageable]) {
        self.replies = replies.suffix(self.maxShownReplies)
        self.collectionView.reloadData()
    }

    func setReplyCount(_ count: Int) {
        self.replyCountLabel.setText("\(count)")
        self.setNeedsLayout()
    }
}

extension MessageCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.replies.count + 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let message: Messageable?
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
        let index = totalCells - indexPath.item - 1
        cell.configureBackground(withIndex: index, message: message)

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

        return -collectionView.height + 60
    }
}

private class TextViewCell: UICollectionViewCell {

    let backgroundColorView = UIView()
    let textView = TextView()
    var index = 0
    var scaleFactor: CGFloat {
        return 1 - CGFloat(self.index) * 0.05
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
        self.backgroundColorView.set(backgroundColor: .lightPurple)

        self.backgroundColorView.addSubview(self.textView)
        self.textView.isScrollEnabled = false
        self.textView.isEditable = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.alpha = self.scaleFactor
        self.backgroundColorView.width = self.width * self.scaleFactor
        self.backgroundColorView.expandToSuperviewHeight()
        self.backgroundColorView.centerOnXAndY()

        self.textView.expandToSuperviewWidth()
        self.textView.sizeToFit()
        self.textView.centerOnXAndY()
    }

    func setText(with message: Messageable) {
        self.textView.text = message.kind.text
        self.setNeedsLayout()
    }

    func configureBackground(withIndex index: Int, message: Messageable) {
        if message.isFromCurrentUser {
            self.backgroundColorView.set(backgroundColor: .lightPurple)
        } else {
            self.backgroundColorView.set(backgroundColor: .orange)
        }
        self.index = index
        self.setNeedsLayout()
    }
}
