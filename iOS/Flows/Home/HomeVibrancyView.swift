//
//  RitualVibrancyView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeVibrancyView: VibrancyView {

    let tabView = HomeTabView()
    private let vibrancyLabel = AnimatingLabel()
    private let countDownView = CountDownView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.vibrancyEffectView.contentView.addSubview(self.vibrancyLabel)
        self.vibrancyLabel.textAlignment = .center

        self.vibrancyEffectView.contentView.addSubview(self.countDownView)
        self.vibrancyEffectView.contentView.addSubview(self.tabView)

        self.countDownView.didExpire = { [unowned self] in
//            if let date = self.feedVC.currentTriggerDate {
//                self.feedVC.state = .feedAvailable(date)
//            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.vibrancyLabel.setSize(withWidth: self.width)
        self.vibrancyLabel.centerOnXAndY()

        self.countDownView.size = CGSize(width: 200, height: 60)
        self.countDownView.centerY = self.halfHeight * 0.8
        self.countDownView.centerOnX()

        let height = 70 + self.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)
    }

    func handle(state: FeedViewController.State) {
        switch state {
        case .noRitual:
            break // Do something
        case .lessThanAnHourAway(let date):
            self.countDownView.startTimer(with: date)
        case .feedAvailable(_):
            break
//            UIView.animate(withDuration: Theme.animationDuration) {
//                self.tabView.alpha = 0
//            }
        case .lessThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.vibrancyLabel.animatedText = "Take a break! ☕️\nSee you at \(dateString)"
        case .moreThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.vibrancyLabel.animatedText = "See you tomorrow at \n\(dateString)"
        case .feedComplete, .feedPaused:
            break
//            UIView.animate(withDuration: Theme.animationDuration) {
//                self.tabView.alpha = 1
//            }
        }
    }

    private func showCountDown() {
        self.countDownView.alpha = 0
        self.countDownView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.vibrancyLabel.alpha = 0
            self.countDownView.transform = .identity
            self.countDownView.alpha = 1
        }, completion: nil)
    }
}
