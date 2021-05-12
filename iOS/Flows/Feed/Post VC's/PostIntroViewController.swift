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
    private let descritpionLabel = Label(font: .small, textColor: .background4)
    private let centerView = View()

    override func initializeViews() {
        super.initializeViews()

        self.centerView.addSubview(self.timeLabel)
        self.centerView.addSubview(self.label)
        self.label.textAlignment = .center
        self.descritpionLabel.textAlignment = .center
    }

    override func configurePost() {
        guard let count = self.post.numberOfUnread else { return }
        self.set(count: count)
    }

    override func getCenterContent() -> UIView {
        return self.centerView
    }

    override func getBottomContent() -> UIView {
        return self.descritpionLabel
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
        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.centerView.expandToSuperviewSize()

        self.timeLabel.setSize(withWidth: self.centerView.width)
        self.timeLabel.centerOnX()
        self.timeLabel.bottom = self.centerView.halfHeight - 5

        self.label.setSize(withWidth: self.centerView.width * 0.9)
        self.label.centerOnX()
        self.label.top = self.centerView.halfHeight + 5

        self.descritpionLabel.setSize(withWidth: self.bottomContainer.width)
        self.descritpionLabel.centerOnX()
        self.descritpionLabel.pin(.bottom)
    }
}
