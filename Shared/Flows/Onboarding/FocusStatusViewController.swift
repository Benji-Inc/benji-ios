//
//  FocusStatusViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 6/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

class FocusStatusViewController: ViewController, Sizeable, Completable {

    let button = Button()

    var onDidComplete: ((Result<INFocusStatusAuthorizationStatus, Error>) -> Void)?

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Allow"))

        self.button.didSelect { [unowned self] in
            INFocusStatusCenter.default.requestAuthorization { status in
                self.complete(with: .success(status))
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()
    }
}
