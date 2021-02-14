//
//  FeedIntroView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class PostIntroViewController: PostViewController {

    private let timeLabel = Label(font: .displayThin, textColor: .lightPurple)
    private let label = Label(font: .regular)
    private let descritpionLabel = Label(font: .small, textColor: .background3)

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.timeLabel)
        self.container.addSubview(self.label)
        self.label.textAlignment = .center
        self.container.addSubview(self.descritpionLabel)
        self.descritpionLabel.textAlignment = .center
    }

    func set(count: Int) {
        if count > 0 {
            let time = count * 20
            let text = LocalizedString(id: "", arguments: [], default: "minutes of distractions avoided today.")
            self.timeLabel.setText("\(time)")
            self.label.setText(text)
        } else {
            self.timeLabel.setText("😌")
            self.label.setText("You had a distraction free day.")
        }

        self.descritpionLabel.setText("Each notification is a 20 minute distraction to your brain.")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.timeLabel.setSize(withWidth: self.container.width)
        self.timeLabel.centerOnX()
        self.timeLabel.bottom = self.container.halfHeight - 5

        self.label.setSize(withWidth: self.container.width * 0.9)
        self.label.centerOnX()
        self.label.top = self.container.halfHeight + 5

        self.descritpionLabel.setSize(withWidth: self.container.width)
        self.descritpionLabel.centerOnX()
        self.descritpionLabel.bottom = self.container.bottom
    }
}
