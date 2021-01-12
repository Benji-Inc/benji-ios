//
//  WelcomeViewController.swift
//  Ours
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
        case loadingReservation
        case foundReservation(Reservation)
        case reservationError
    }

    private let signupButton = Button()
    private let reservationButton = Button()
    private var reservationId: String?

    @Published var state: State = .welcome

    init() {
        super.init(textField: TextField(),
                   title: LocalizedString(id: "", default: "RSVP #"),
                   placeholder: LocalizedString(id: "", default: ""))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.textField.alpha = 0

        self.view.addSubview(self.signupButton)
        self.signupButton.set(style: .normal(color: .lightPurple, text: "Sign-Up/Login"))

        self.signupButton.didSelect { [unowned self] in
            self.state = .signup
        }

        self.view.addSubview(self.reservationButton)
        self.reservationButton.set(style: .normal(color: .lightPurple, text: "Claim RSVP"))
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
        self.reservationButton.pinToSafeArea(.bottom, padding: 0)
        self.reservationButton.centerOnX()

        self.signupButton.setSize(with: self.view.width)
        self.signupButton.match(.bottom, to: .top, of: self.reservationButton, offset: 10)
        self.signupButton.centerOnX()
    }

    private func animate(for state: State) {
        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .welcome:
                self.reservationButton.alpha = 1
                self.signupButton.alpha = 1
            case .signup:
                break
            case .reservationInput:
                self.reservationButton.alpha = 0
                self.signupButton.alpha = 0
            case .loadingReservation:
                break
            case .foundReservation(_):
                break
            case .reservationError:
                break 
            }
        } completion: { (completed) in
            switch state {
            case .reservationInput:
                UIView.animate(withDuration: Theme.animationDuration) {
                    self.textField.alpha = 1
                }
            default:
                break
            }
        }
    }

    override func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }

        let tf = self.textField as? TextField
        tf?.animationView.play()
        Reservation.localThenNetworkQuery(for: text)
            .mainSink(receivedResult: { (result) in
                switch result {
                case .success(let reservation):
                    if reservation.isClaimed {
                        self.state = .reservationError
                    } else {
                        self.state = .foundReservation(reservation)
                    }
                case .error(_):
                    self.state = .reservationError
                }
                tf?.animationView.stop()
            }).store(in: &self.cancellables)
    }
}
