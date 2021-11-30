//
//  WelcomeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class WelcomeViewController: TextInputViewController<Void> {

    enum State {
        case welcome
        case login
        case reservationInput
        case foundReservation(Reservation)
        case reservationError
    }

    private let label = Label(font: .display, textColor: .textColor)
    private let loginButton = Button()
    private let reservationButton = Button()
    private var reservationId: String?

    @Published var state: State = .welcome

    init() {
        super.init(textField: TextField(), placeholder: LocalizedString(id: "RSVP CODE", default: ""))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldBecomeFirstResponder() -> Bool {
        return false
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.label)
        self.label.setText("Jibber")

        self.textEntry.alpha = 0
        self.textField.autocapitalizationType = .none
        self.textField.autocorrectionType = .no

        self.view.addSubview(self.loginButton)
        self.loginButton.set(style: .normal(color: .clear, text: "Login"))

        self.loginButton.didSelect { [unowned self] in
            self.state = .login
        }

        self.view.addSubview(self.reservationButton)
        self.reservationButton.set(style: .normal(color: .white, text: "RSVP"))
        self.reservationButton.didSelect { [unowned self] in
            self.state = .reservationInput
        }

        self.$state.mainSink { [unowned self] (state) in
            self.animate(for: state)
        }.store(in: &self.cancellables)

        self.view.onDoubleTap { [unowned self] _ in
            if self.textField.isFirstResponder {
                self.textField.resignFirstResponder()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.label.setSize(withWidth: self.view.width)
        self.label.centerOnX()
        self.label.centerY = self.view.halfHeight * 0.6

        self.reservationButton.setSize(with: self.view.width)
        self.reservationButton.pinToSafeArea(.bottom, offset: .xtraLong)
        self.reservationButton.centerOnX()

        self.loginButton.setSize(with: self.view.width)
        self.loginButton.width = 80
        self.loginButton.pinToSafeAreaRight()
        self.loginButton.pinToSafeAreaTop()
    }

    private func animate(for state: State) {
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            switch state {
            case .welcome:
                self.textEntry.alpha = 0 
                self.reservationButton.alpha = 1
                self.loginButton.alpha = 1
            case .login:
                break
            case .reservationInput:
                self.reservationButton.alpha = 0
                self.loginButton.alpha = 0
            case .foundReservation(_):
                break
            case .reservationError:
                self.reservationButton.alpha = 1
                self.loginButton.alpha = 1
            }
        } completion: { (completed) in
            switch state {
            case .reservationInput:
                UIView.animate(withDuration: Theme.animationDurationStandard) {
                    self.textEntry.alpha = 1
                } completion: { (completed) in
                    self.textField.becomeFirstResponder()
                }
            case .reservationError:
                self.textField.resignFirstResponder()
            default:
                break
            }
        }
    }

    override func validate(text: String) -> Bool {
        return !text.isEmpty
    }

    override func didTapButton() {
        guard let code = self.textField.text, !code.isEmpty else {
            self.state = .welcome
            return
        }
        
        Task {
            await self.claimRSVP(code: code)
        }.add(to: self.taskPool)
    }

    override func textFieldDidEndEditing(_ textField: UITextField) {

        guard let code = self.textField.text, !code.isEmpty else {
            self.state = .welcome
            return
        }

        Task {
            await self.claimRSVP(code: code)
        }.add(to: self.taskPool)
    }

    private func claimRSVP(code: String) async {

        await self.button.handleEvent(status: .loading)

        do {
            let reservation = try await Reservation.getObject(with: code)

            if reservation.isClaimed {
                self.state = .reservationError
            } else {
                self.state = .foundReservation(reservation)
            }
            await self.button.handleEvent(status: .complete)
        } catch {
            await self.button.handleEvent(status: .error(error.localizedDescription))
            self.state = .reservationError
        }
    }
}
