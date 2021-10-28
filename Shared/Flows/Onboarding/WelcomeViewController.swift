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
        case signup
        case reservationInput
        case foundReservation(Reservation)
        case reservationError
    }

    private let signupButton = Button()
    private let reservationButton = Button()
    private var reservationId: String?

    @Published var state: State = .welcome

    init() {
        super.init(textField: TextField(),
                   title: LocalizedString(id: "", default: "Enter RSVP #"),
                   placeholder: LocalizedString(id: "", default: ""))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldBecomeFirstResponder() -> Bool {
        return false
    }

    override func initializeViews() {
        super.initializeViews()

        self.textEntry.alpha = 0

        self.view.addSubview(self.signupButton)
        self.signupButton.set(style: .normal(color: .gray, text: "Login / Join"))

        self.signupButton.didSelect { [unowned self] in
            self.state = .signup
        }

        self.view.addSubview(self.reservationButton)
        self.reservationButton.set(style: .normal(color: .darkGray, text: "Claim RSVP"))
        self.reservationButton.didSelect { [unowned self] in
            self.state = .reservationInput
        }

        self.$state.mainSink { [unowned self] (state) in
            self.animate(for: state)
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.reservationButton.setSize(with: self.view.width)
        self.reservationButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.reservationButton.centerOnX()

        self.signupButton.setSize(with: self.view.width)
        self.signupButton.match(.bottom, to: .top, of: self.reservationButton, offset: -Theme.contentOffset.half)
        self.signupButton.centerOnX()
    }

    private func animate(for state: State) {
        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .welcome:
                self.textEntry.alpha = 0 
                self.reservationButton.alpha = 1
                self.signupButton.alpha = 1
            case .signup:
                break
            case .reservationInput:
                self.reservationButton.alpha = 0
                self.signupButton.alpha = 0
            case .foundReservation(_):
                break
            case .reservationError:
                self.reservationButton.alpha = 1
                self.signupButton.alpha = 1
            }
        } completion: { (completed) in
            switch state {
            case .reservationInput:
                UIView.animate(withDuration: Theme.animationDuration) {
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

    override func textFieldDidChange() {
        super.textFieldDidChange()

        if let text = self.textField.text, !text.isEmpty {
            self.textEntry.button.isEnabled = true

        } else {
            self.textEntry.button.isEnabled = false
        }
    }

    override func didTapButton() {
        Task {
            await self.claimRSVP()
        }
    }

    override func textFieldDidEndEditing(_ textField: UITextField) {
        Task {
            await self.claimRSVP()
        }
    }

    private func claimRSVP() async {
        guard let code = self.textField.text, !code.isEmpty else {
            self.state = .welcome
            return
        }

        await self.textEntry.button.handleEvent(status: .loading)

        do {
            let reservation = try await Reservation.getObject(with: code)

            if reservation.isClaimed {
                self.state = .reservationError
            } else {
                self.state = .foundReservation(reservation)
            }
            await self.textEntry.button.handleEvent(status: .complete)
        } catch {
            await self.textEntry.button.handleEvent(status: .error(error.localizedDescription))
            self.state = .reservationError
        }
    }
}
