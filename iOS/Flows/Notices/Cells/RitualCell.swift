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
    private let button = Button()
    private let countDownView = CountDownView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.label.textAlignment = .center

        self.addSubview(self.countDownView)

        self.addSubview(self.button)

        self.button.set(style: .normal(color: .purple, text: "Begin"))

        self.countDownView.didExpire = {
            RitualManager.shared.state = .feedAvailable
        }

        RitualManager.shared.$state.mainSink { state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - Theme.contentOffset)
        self.label.centerOnX()
        self.label.centerY = self.contentView.height * 0.35

        self.button.size = CGSize(width: 160, height: 40)
        self.button.pin(.bottom, padding: Theme.contentOffset.half)
        self.button.centerOnX()

        self.countDownView.size = CGSize(width: 200, height: 60)
        self.countDownView.centerOnXAndY()
    }

    func handle(state: RitualManager.State) {
        switch state {
        case .initial:
            self.label.animatedText = "Loading..."
            self.button.alpha = 0
        case .noRitual:
            self.label.animatedText = "Set your ritual time."
            self.button.alpha = 0
        case .lessThanAnHourAway(let date):
            self.label.animatedText = ""
            self.countDownView.startTimer(with: date)
            self.showCountDown()
            self.button.alpha = 0
        case .feedAvailable:
            self.showRitualReady()
        case .lessThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "Take a break! ☕️\nSee you at \(dateString)"
            self.button.alpha = 0
        case .moreThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "See you tomorrow at \n\(dateString)"
            self.button.alpha = 0
        }

        self.layoutNow()
    }

    func showRitualReady() {
        self.label.animatedText = "Your feed is unlocked!"
        self.button.alpha = 1
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





