//
//  InviteSectionHeader.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InviteSectionHeader: UICollectionReusableView {

    private(set) var label = RegularBoldLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {

        self.addSubview(self.label)

        self.set(backgroundColor: .clear)
        self.label.set(text: "Foo")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - (Theme.contentOffset * 2))
        self.label.left = Theme.contentOffset
        self.label.centerOnY()
    }
}
