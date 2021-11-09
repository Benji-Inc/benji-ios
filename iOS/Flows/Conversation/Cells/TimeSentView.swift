//
//  TimeSentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// Layout attributes that can be used to configure a TimeSentView.
class TimeSentViewLayoutAttributes: UICollectionViewLayoutAttributes {

    /// The date we want displayed on the TimeSentView
    var timeSent: Date?

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! TimeSentViewLayoutAttributes
        copy.timeSent = self.timeSent
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? TimeSentViewLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.timeSent == self.timeSent
        }

        return false
    }
}

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

    override func layoutSubviews() {
        super.layoutSubviews()

        self.daysAgoLabel.setSize(withWidth: self.width)
        self.daysAgoLabel.pin(.left, padding: Theme.contentOffset)
        self.daysAgoLabel.centerOnY()

        self.timeOfDayLabel.setSize(withWidth: self.width)
        self.timeOfDayLabel.pin(.right, padding: Theme.contentOffset)
        self.timeOfDayLabel.centerOnY()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let timeSentAttributes = layoutAttributes as? TimeSentViewLayoutAttributes {
            self.timeOfDayLabel.set(date: timeSentAttributes.timeSent)
            self.daysAgoLabel.set(date: timeSentAttributes.timeSent)
        }

        self.setNeedsLayout()
    }
}
