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
            switch state {
            case .welcome:
                break
            case .signup:
                break
            case .reservationInput:
                break
            case .loadingReservation:
                break
            case .foundReservation(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()


    }
}
