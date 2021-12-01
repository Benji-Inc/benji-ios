//
//  ReactionsCountView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsCountView: UICollectionReusableView {

    let label = Label(font: .small)

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

    func configure(with remaining: Int) {
        guard remaining > 0 else { return }

        self.label.setText("+\(remaining)")
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
