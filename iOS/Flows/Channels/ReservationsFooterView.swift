//
//  ReservationsFooterView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ReservationsFooterView: UICollectionReusableView {

    let label = Label(font: .regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeSubviews()
    }

    func initializeSubviews() {
        self.addSubview(self.label)
        self.backgroundColor = .red 
    }

    func configure(with count: Int) {

        let text = LocalizedString(id: "", arguments: [String(count)], default: "You have @(invites)")
        self.label.setText(text)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.label.centerOnXAndY()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 60)
        return layoutAttributes
    }
}
