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

    let label = Label(font: .small)
    let button = Button()

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
        self.label.setTextColor(.background3)
        self.label.textAlignment = .center
        self.addSubview(self.button)

        self.button.set(style: .normal(color: .purple, text: "Share"))
    }

    func configure(with count: Int) {

        let countString = String(count)
        let text = LocalizedString(id: "", arguments: [countString], default: "You have @(invites) reservations left.")
        self.label.setText(text)
        let countAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: FontType.smallBold.font,
                                                              NSAttributedString.Key.kern: FontType.smallBold.kern,
                                                              NSAttributedString.Key.foregroundColor: Color.background3.color]
        self.label.add(attributes: countAttributes, to: countString)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.size = CGSize(width: 160, height: 40)
        self.button.centerOnX()
        self.button.pin(.bottom)

        self.label.setSize(withWidth: self.button.width)
        self.label.centerOnX()
        self.label.match(.bottom, to: .top, of: self.button, offset: -Theme.contentOffset)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 120)
        return layoutAttributes
    }
}
