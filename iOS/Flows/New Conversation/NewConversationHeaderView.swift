//
//  NewConversationHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewConversationHeaderView: UICollectionReusableView {

    let titleLabel = Label(font: .regularBold)
    let descriptionLabel = Label(font: .small)
    /// Place all views under the lineView
    let lineView = View()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .background3)

        self.titleLabel.setText("Create Conversation")
        self.titleLabel.textAlignment = .center
        self.titleLabel.stringCasing = .uppercase

        self.descriptionLabel.textAlignment = .center
        self.descriptionLabel.setText("Tap people below to add them to a new conversation.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.setSize(withWidth: self.width * 0.8)
        self.titleLabel.pin(.top, padding: Theme.contentOffset)
        self.titleLabel.centerOnX()

        self.descriptionLabel.setSize(withWidth: self.width * 0.8)
        self.descriptionLabel.top = self.titleLabel.bottom + 20
        self.descriptionLabel.centerOnX()

        self.lineView.size = CGSize(width: self.width - Theme.contentOffset.doubled, height: 2)
        self.lineView.top = self.descriptionLabel.bottom + 20
        self.lineView.centerOnX()
    }
}
