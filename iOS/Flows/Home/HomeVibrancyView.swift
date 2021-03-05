//
//  RitualVibrancyView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeVibrancyView: VibrancyView {

    let tabView = HomeTabView()
    private let vibrancyLabel = AnimatingLabel()
    private let countDownView = CountDownView()
    let button = Button()
    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.vibrancyEffectView.contentView.addSubview(self.vibrancyLabel)
        self.vibrancyLabel.textAlignment = .center

        self.vibrancyEffectView.contentView.addSubview(self.countDownView)
        self.vibrancyEffectView.contentView.addSubview(self.tabView)
        self.vibrancyEffectView.contentView.addSubview(self.button)
        self.button.alpha = 0

        self.countDownView.didExpire = { [unowned self] in
            self.button.set(style: .normal(color: .white, text: "Begin"))
            self.showButton()
        }

        RitualManager.shared.$state.mainSink { state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.vibrancyLabel.setSize(withWidth: self.width)
        self.vibrancyLabel.centerY = self.centerY * 0.8
        self.vibrancyLabel.centerOnX()

        self.countDownView.size = CGSize(width: 200, height: 60)
        self.countDownView.match(.top, to: .bottom, of: self.vibrancyLabel, offset: 10)
        self.countDownView.centerOnX()

        self.button.size = CGSize(width: 140, height: 40)
        self.button.match(.top, to: .bottom, of: self.vibrancyLabel, offset: 10)
        self.button.centerOnX()

        let height = 70 + self.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)
    }

    func handle(state: RitualManager.State) {
        switch state {
        case .noRitual:
            self.vibrancyLabel.animatedText = "Set your ritual time."
            self.button.set(style: .normal(color: .white, text: "set"))
            self.showButton()
        case .lessThanAnHourAway(let date):
            self.vibrancyLabel.animatedText = ""
            self.countDownView.startTimer(with: date)
            self.showCountDown()
        case .feedAvailable(_):
            self.vibrancyLabel.animatedText = "Are you ready?"
            self.showButton()
        case .lessThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.vibrancyLabel.animatedText = "Take a break! ☕️\nSee you at \(dateString)"
        case .moreThanHourAfter(let date):
            let dateString = Date.hourMinuteTimeOfDay.string(from: date)
            self.vibrancyLabel.animatedText = "See you tomorrow at \n\(dateString)"
        }

        self.layoutNow()
    }

    private func showButton() {
        self.button.alpha = 0
        self.button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.countDownView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.countDownView.alpha = 0
            self.button.transform = .identity
            self.button.alpha = 1
        }, completion: nil)
    }

    private func showCountDown() {
        self.countDownView.alpha = 0
        self.countDownView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.button.alpha = 0
            self.countDownView.transform = .identity
            self.countDownView.alpha = 1
        }, completion: nil)
    }

    private func hideAll() {
        self.vibrancyLabel.animatedText = ""

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.countDownView.alpha = 0
            self.button.alpha = 0
            self.tabView.alpha = 0
        }, completion: nil)
    }
}
