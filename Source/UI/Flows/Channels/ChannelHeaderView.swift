//
//  ChannelTitleView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/1/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

struct ChannelHeaderModel: Equatable {
    static func == (lhs: ChannelHeaderModel, rhs: ChannelHeaderModel) -> Bool {
        return lhs.title.identifier == rhs.title.identifier 
    }

    let title: Localized
    let subtitle: Localized
}

class ChannelHeaderView: View {
    private let titleLabel = DisplayLabel()
    private let subtitleLabel = MediumLabel()
    private var firstHeader: ChannelHeaderModel?
    private var secondHeader: ChannelHeaderModel?
    private weak var firstSnapshot: UIView?
    private weak var secondSnapshot: UIView?
    private var animator: UIViewPropertyAnimator?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
    }

    private func reset() {
        self.firstSnapshot?.removeFromSuperview()
        self.secondSnapshot?.removeFromSuperview()
        self.firstHeader = nil
        self.secondHeader = nil
        self.titleLabel.alpha = 1
        self.subtitleLabel.alpha = 1
    }

    func set(model: ChannelHeaderModel) {
        self.reset()
        self.titleLabel.set(text: model.title)
        self.subtitleLabel.set(text: model.subtitle)
        self.layoutNow()
    }

    func transition(between first: ChannelHeaderModel,
                    second: ChannelHeaderModel,
                    progress: CGFloat) {

        guard first != self.firstHeader, second != self.secondHeader else {
            self.animator?.fractionComplete = progress
            return
        }

        self.reset()

        self.firstHeader = first
        self.secondHeader = second

        self.titleLabel.set(text: first.title)
        self.subtitleLabel.set(text: second.subtitle)

        self.layoutIfNeeded()

        let firstSnapshot = self.renderSnapshot()
        self.firstSnapshot = firstSnapshot

        self.titleLabel.set(text: second.title)
        self.subtitleLabel.set(text: second.subtitle)

        self.layoutIfNeeded()
        let secondSnapshot = self.renderSnapshot()
        self.secondSnapshot = secondSnapshot

        self.addSubview(firstSnapshot)
        self.addSubview(secondSnapshot)

        firstSnapshot.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        secondSnapshot.center = CGPoint(x: self.bounds.midX, y: self.bounds.maxY)
        secondSnapshot.alpha = 0
        self.titleLabel.alpha = 0
        self.subtitleLabel.alpha = 0

        self.animator?.stopAnimation(true)
        self.animator = UIViewPropertyAnimator(duration: 1, curve: .linear, animations: { [bounds] in
            firstSnapshot.center = CGPoint(x: bounds.midX, y: bounds.minY)
            firstSnapshot.alpha = 0
            secondSnapshot.center = CGPoint(x: bounds.midX, y: bounds.midY)
            secondSnapshot.alpha = 1
        })
        self.animator?.fractionComplete = progress
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.pin(.top)
        self.titleLabel.pin(.left)

        self.subtitleLabel.setSize(withWidth: self.width)
        self.subtitleLabel.pin(.bottom)
        self.subtitleLabel.pin(.left)
    }
}
