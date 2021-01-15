//
//  RitualInputViewController.swift
//  Benji
//
//  Created by Martin Young on 8/13/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications
import TMROLocalization
import Combine

private let minutesInADay: CGFloat = 1440

private func round(num: CGFloat, toMultipleOf multiple: Int) -> Int {
    let rounded = (num/CGFloat(multiple)).rounded(.toNearestOrAwayFromZero) * CGFloat(multiple)
    return Int(rounded)
}

class RitualInputViewController: ViewController {

    enum State {
        case needsAuthorization
        case edit
        case update
    }

    static let height: CGFloat = 500
    let content = RitualInputContentView()

    var selectedDate = Date()
    @Published var state: State = .edit

    var didTapNeedsAthorization: CompletionOptional = nil

    override func loadView() {
        self.view = self.content
    }

    override func initializeViews() {
        super.initializeViews()

        self.$state
            .removeDuplicates()
            .mainSink { (state) in
                self.updateForStateChange()
            }.store(in: &self.cancellables)

        UserNotificationManager.shared.getNotificationSettings()
            .mainSink { (settings) in
                if settings.authorizationStatus != .authorized {
                    self.state = .needsAuthorization
                }
            }.store(in: &self.cancellables)

        self.content.timeHump.$percentage.mainSink { [weak self] (percentage) in
            guard let `self` = self else { return }
            let calendar = Calendar.current
            var components = DateComponents()

            // Move minutes in intervals of 5
            let minutes = round(num: (percentage * minutesInADay), toMultipleOf: 5)
            components.minute = minutes

            if let date = calendar.date(from: components) {
                self.selectedDate = date
                self.content.set(date: date)
            }
        }.store(in: &self.cancellables)

        if let ritual = User.current()?.ritual {
            ritual.retrieveDataIfNeeded()
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let r):
                        self.updateHump(with: r.timeComponents)
                    case .error(_):
                        self.setDefault()
                    }
                }).store(in: &self.cancellables)
        } else {
            self.setDefault()
        }

        self.content.minusButton.didSelect { [unowned self] in
            if let newDate = self.selectedDate.subtract(component: .minute, amount: 15) {
                let minute = round(num: CGFloat(newDate.minute), toMultipleOf: 15)
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day,
                                                                      .hour, .minute, .second],
                                                                     from: newDate)
                dateComponents.minute = minute
                self.updateHump(with: dateComponents)
            }
        }

        self.content.plusButton.didSelect { [unowned self] in
            if let newDate = self.selectedDate.add(component: .minute, amount: 15) {
                let minute = round(num: CGFloat(newDate.minute), toMultipleOf: 15)
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day,
                                                                      .hour, .minute, .second],
                                                                     from: newDate)
                dateComponents.minute = minute
                self.updateHump(with: dateComponents)
            }
        }

        self.content.confirmButton.didSelect { [unowned self] in
            switch self.state {
            case .needsAuthorization:
                self.didTapNeedsAthorization?()
            case .edit:
                self.state = .update
            case .update:
                self.saveRitual()
            }
        }
    }

    private func saveRitual() {
        let ritual = Ritual()
        ritual.create(with: self.selectedDate)
        User.current()?.ritual = ritual
        User.current()?.saveLocalThenServer()
            .mainSink(receivedResult: { (result) in
                switch result {
                case .success(_):
                    self.animateButton(with: .lightPurple, text: "Success")
                case .error(_):
                    self.animateButton(with: .red, text: "Error")
                }
                delay(2) {
                    self.state = .edit
                }
            }).store(in: &self.cancellables)
    }

    private func updateForStateChange() {
        switch self.state {
        case .needsAuthorization:
            self.animateButton(with: .green, text: "Authorize")
            self.content.animateContent(shouldShow: false)
        case .edit:
            self.animateButton(with: .green, text: "Edit")
            self.content.animateContent(shouldShow: false)
        case .update:
            self.animateButton(with: .purple, text: "Update")
            self.content.animateContent(shouldShow: true)
        }
    }

    private func animateButton(with color: Color, text: Localized) {
        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.content.confirmButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.content.confirmButton.alpha = 0
        }) { (completed) in
            self.content.confirmButton.set(style: .normal(color: color, text: text))
            UIView.animate(withDuration: Theme.animationDuration) {
                self.content.confirmButton.transform = .identity
                self.content.confirmButton.alpha = 1
            }
        }
    }
    
    private func setDefault() {
        var dateComponents = Calendar.current.dateComponents([.hour, .minute],
                                                             from: Date.today)
        dateComponents.hour = 19
        dateComponents.minute = 0
        self.updateHump(with: dateComponents)
    }

    private func updateHump(with components: DateComponents) {
        var totalSeconds = CGFloat(components.second ?? 0)
        totalSeconds += CGFloat(components.minute ?? 0) * 60
        totalSeconds += CGFloat(components.hour ?? 0) * 3600
        self.content.timeHump.percentage = totalSeconds/86400
    }
}
