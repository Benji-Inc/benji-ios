//
//  PeopleHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PeopleHeaderView: UICollectionReusableView {

    let titleLabel = ThemeLabel(font: .regularBold)
    let descriptionLabel = ThemeLabel(font: .small)
    /// Place all views under the lineView
    let lineView = BaseView()

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
        self.lineView.set(backgroundColor: .B1)

        self.titleLabel.textAlignment = .center
        self.titleLabel.stringCasing = .uppercase

        self.descriptionLabel.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.pinToSafeAreaTop()
        self.titleLabel.centerOnX()

        self.descriptionLabel.setSize(withWidth: self.width)
        self.descriptionLabel.top = self.titleLabel.bottom + 20
        self.descriptionLabel.centerOnX()

        self.lineView.size = CGSize(width: self.width, height: 2)
        self.lineView.top = self.descriptionLabel.bottom + 20
        self.lineView.centerOnX()
    }
}
