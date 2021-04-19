//
//  ReservationsViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationsViewController: ViewController {

    let label = Label(font: .display)
    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.label)
        self.label.setText("Some text about sharing")

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Share"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.label.setSize(withWidth: self.view.width * 0.8)
        self.label.centerOnXAndY()

        self.button.setSize(with: self.view.width - Theme.contentOffset.doubled)
        self.button.centerOnX()
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)

    }
}
