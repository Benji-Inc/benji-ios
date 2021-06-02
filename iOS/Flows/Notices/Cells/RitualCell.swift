//
//  RitualCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/31/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RitualCell: NoticeCell {

    private let label = AnimatingLabel()
    private let countDownView = CountDownView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.label.textAlignment = .center

        self.addSubview(self.countDownView)

        self.countDownView.didExpire = {
            RitualManager.shared.state = .feedAvailable
        }

        RitualManager.shared.$state.mainSink { state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.contentView.width - Theme.contentOffset)
        self.label.left = self.contentView.halfWidth - self.label.halfWidth
        self.label.top = self.contentView.halfHeight - self.label.halfHeight

        self.countDownView.size = CGSize(width: 200, height: 60)
        self.countDownView.left = self.contentView.halfWidth - self.countDownView.halfWidth
        self.countDownView.top = self.contentView.halfHeight - self.countDownView.halfHeight
    }

    func handle(state: RitualManager.State) {
        switch state {
        case .initial:
            self.label.animatedText = "Loading..."
        case .noRitual:
            self.label.animatedText = "Set your ritual time."
        case .lessThanAnHourAway(let date):
            self.label.animatedText = ""
            self.countDownView.startTimer(with: date)
            self.showCountDown()
        case .feedAvailable:
            self.showRitualReady()
        case .lessThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "Take a break! ☕️\nSee you at \(dateString)"
        case .moreThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "See you tomorrow at \n\(dateString)"
        }

        self.layoutNow()
    }

    func showRitualReady() {
        self.label.animatedText = "Your feed is unlocked!"
    }

    private func showCountDown() {
        self.countDownView.alpha = 0
        self.countDownView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.countDownView.transform = .identity
            self.countDownView.alpha = 1
        }, completion: nil)
    }

    func hideAll() {
        self.label.animatedText = ""

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.countDownView.alpha = 0
        }, completion: nil)
    }

    override func reset() {
        self.handle(state: .feedAvailable)
    }
}





