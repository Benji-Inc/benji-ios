//
//  new_MessageCell.swift
//  new_MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class new_MessageCell: UICollectionViewCell {

    let textView = TextView()
    let replyCountLabel = Label(font: .regular)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.replyCountLabel)

        self.contentView.addSubview(self.textView)
        self.textView.isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.replyCountLabel.sizeToFit()
        self.replyCountLabel.pin(.right)
        self.replyCountLabel.pin(.top)

        self.textView.width = self.contentView.width
        self.textView.sizeToFit()
        self.textView.centerOnXAndY()
    }
}
