//
//  TodayHeaderView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveHeaderView: UICollectionReusableView {

    let label = Label(font: .mediumThin)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {
        self.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.pin(.left)
        self.label.centerOnY()
    }
}
