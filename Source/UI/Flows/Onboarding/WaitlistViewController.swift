//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization

class WaitlistViewController: ViewController, Sizeable {

    let positionLabel = Label(font: .small)
    let remainingLabel = Label(font: .display)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.positionLabel)
        self.view.addSubview(self.remainingLabel)

        if let position = User.current()?.quePosition {
            let positionString = LocalizedString(id: "", arguments: [String(position)], default: "Your positon is: @(position)")
            self.positionLabel.setText(positionString)

            PFConfig.getInBackground { [weak self]( config, error) in
                guard let `self` = self else { return }

                if let max = config?.object(forKey: "maxQuePosition") as? Int,
                   let claimed = config?.object(forKey: "claimedPositon") as? Int {

                    let remaining = (position + claimed) - max

                    self.remainingLabel.setText(String(remaining))
                    self.view.layoutNow()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.remainingLabel.setSize(withWidth: self.view.width)
        self.remainingLabel.centerOnX()
        self.remainingLabel.bottom = self.view.halfHeight * 0.8

        self.positionLabel.setSize(withWidth: self.view.width)
        self.positionLabel.match(.top, to: .bottom, of: self.remainingLabel, offset: 20)
        self.positionLabel.centerOnX()
    }
}
