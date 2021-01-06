//
//  RoutineInputViewController.swift
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

enum RoutineInputState {
    case needsAuthorization
    case edit
    case update
}

class RitualInputViewController: ViewController {

    static let height: CGFloat = 500
    let content = RitualInputContentView()

    var selectedDate = Date()
    @Published var state: RoutineInputState = .edit

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

        if UserNotificationManager.shared.getNotificationSettingsSynchronously().authorizationStatus != .authorized {
            self.state = .needsAuthorization
        }

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

        User.current()?.getRitual()
        .observe(with: { (result) in
            switch result {
            case .success(let routine):
                self.updateHump(with: routine.timeComponents)
            case .failure(_):
                self.setDefault()
            }
        })

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

        self.content.setRoutineButton.didSelect { [unowned self] in
            switch self.state {
            case .needsAuthorization:
                self.didTapNeedsAthorization?()
            case .edit:
                self.state = .update
            case .update:
                self.saveRoutine()
            }
        }
    }

    private func saveRoutine() {
        let ritual = Ritual()
        ritual.create(with: self.selectedDate)
        ritual.saveEventually()
        .ignoreUserInteractionEventsUntilDone(for: [self.view])
            .observe { (result) in
                switch result {
                case .success(_):
                    self.animateButton(with: .lightPurple, text: "Success")
                case .failure(_):
                    self.animateButton(with: .red, text: "Error")
                }

                delay(2) {
                    self.state = .edit
                }
        }
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
            self.content.setRoutineButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.content.setRoutineButton.alpha = 0
        }) { (completed) in
            self.content.setRoutineButton.set(style: .normal(color: color, text: text))
            UIView.animate(withDuration: Theme.animationDuration) {
                self.content.setRoutineButton.transform = .identity
                self.content.setRoutineButton.alpha = 1
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
