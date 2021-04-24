//
//  ArchiveFooterView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveFooterView: UICollectionReusableView {

    let button = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {
        self.addSubview(self.button)
        self.button.set(style: .normal(color: .lightPurple, text: "show more"))
    }

    func configure(showButton: Bool) {
        self.button.isHidden = !showButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.size = CGSize(width: 128, height: 40)
        self.button.centerOnX()
        self.button.pin(.top, padding: Theme.contentOffset)
    }
}

