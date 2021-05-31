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

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()

        self.countDownView.size = CGSize(width: 200, height: 60)
        self.countDownView.centerOnXAndY()
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
            ToastScheduler.shared.schedule(toastType: .basic(displayable: UIImage(systemName: "lock.open")!, title: "Unlocked", description: "Your ritual has begun! You now have access to all features."))
        case .lessThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "Take a break! ☕️\nSee you at \(dateString)"
        case .moreThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.label.animatedText = "See you tomorrow at \n\(dateString)"
        }

        self.layoutNow()
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





