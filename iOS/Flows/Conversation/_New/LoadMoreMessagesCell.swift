//
//  LoadMoreMessagesCell.swift
//  Jibber
//
//  Created by Martin Young on 9/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LoadMoreMessagesCell: UICollectionViewCell {

    private(set) var button = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.addSubview(self.button)

        self.button.set(style: .rounded(color: .orange, text: "LOAD MORE"))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.size = CGSize(width: 140, height: 34)
        self.button.centerOnXAndY()
    }
}

