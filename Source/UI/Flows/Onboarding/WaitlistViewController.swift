//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WaitlistViewController: ViewController, Sizeable {

    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .blue, text: "Go"))
        self.button.didSelect {
            // Do something
            print("did press button")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.pin(.bottom)
        self.button.centerOnX()
    }
}
