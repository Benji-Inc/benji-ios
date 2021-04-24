//
//  ArchiveHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ArchiveHeaderView: UICollectionReusableView {

    let nameLabel = Label(font: .display)
    let handleLabel = Label(font: .smallBold, textColor: .background3)
    let ritualLabel = Label(font: .regular, textColor: .background4)

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    func initializeSubviews() {
        self.addSubview(self.nameLabel)
        self.addSubview(self.handleLabel)
        self.addSubview(self.ritualLabel)
    }

    func configure(with user: User) {
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.nameLabel.setText(user.fullName)
                self.handleLabel.setText(user.handle)
                self.setTextFor(ritual: user.ritual)
                self.layoutNow()
            }).store(in: &self.cancellables)
    }

    func setTextFor(ritual: Ritual?) {
        if let r = ritual {
            r.fetchIfNeededInBackground(block: { (object, error) in
                if let ritual = object as? Ritual, let date = ritual.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    let string = formatter.string(from: date)
                    self.ritualLabel.setText("Ritual starts at: \(string)")
                    self.layoutNow()
                }
            })

        } else {
            self.ritualLabel.setText("No ritual set")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.nameLabel.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.nameLabel.pin(.top, padding: Theme.contentOffset.half)
        self.nameLabel.pin(.left)

        self.handleLabel.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.handleLabel.match(.top, to: .bottom, of: self.nameLabel, offset: Theme.contentOffset.half.half)
        self.handleLabel.pin(.left)

        self.ritualLabel.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.ritualLabel.match(.top, to: .bottom, of: self.handleLabel, offset: Theme.contentOffset.half)
        self.ritualLabel.pin(.left)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        super.preferredLayoutAttributesFitting(layoutAttributes)

        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: self.ritualLabel.bottom + Theme.contentOffset)
        return layoutAttributes
    }
}
