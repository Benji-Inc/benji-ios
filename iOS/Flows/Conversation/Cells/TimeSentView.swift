//
//  TimeSentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TimeSentView: UICollectionReusableView {

    let timeOfDayLabel = MessageTimeLabel()
    let daysAgoLabel = MessageDateLabel()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeSubviews() {
        self.addSubview(self.timeOfDayLabel)
        self.addSubview(self.daysAgoLabel)
    }

    func configure(with message: Messageable) {
        self.timeOfDayLabel.set(date: message.createdAt)
        self.daysAgoLabel.set(date: message.createdAt)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.daysAgoLabel.setSize(withWidth: self.width)
        self.daysAgoLabel.pin(.left, padding: Theme.contentOffset)
        self.daysAgoLabel.pin(.bottom, padding: Theme.contentOffset.half.half)

        self.timeOfDayLabel.setSize(withWidth: self.width)
        self.timeOfDayLabel.pin(.right, padding: Theme.contentOffset)
        self.timeOfDayLabel.pin(.bottom, padding: Theme.contentOffset.half.half)
    }
}
