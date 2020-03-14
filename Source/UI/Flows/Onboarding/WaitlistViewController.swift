//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 3/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WaitlistViewController: FullScreenViewController {

    let label = DisplayLabel()
    let positionLabel = RegularLabel()

    override func initializeViews() {
        super.initializeViews()

        self.contentContainer.addSubview(self.label)
        self.contentContainer.addSubview(self.positionLabel)
    }

    func set(position: Int) {

        self.label.set(text: "You are on the list!", color: .white, alignment: .center, stringCasing: .unchanged)

        self.positionLabel.set(text: String(position), color: .white, alignment: .center, stringCasing: .uppercase)
        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.positionLabel.setSize(withWidth: self.view.width)
        self.positionLabel.centerOnXAndY()

        self.label.setSize(withWidth: self.view.width * 0.8)
        self.label.bottom = self.positionLabel.top - 20
        self.label.centerOnX()
    }
}
