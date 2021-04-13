//
//  DetailButton.swift
//  Ours
//
//  Created by Benji Dodgson on 4/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class CommentsButton: View {

    let label = Label(font: .small, textColor: .white)
    let imageView = UIImageView(image: UIImage(systemName: "text.bubble.fill"))

    override func initializeSubviews() {
        super.initializeSubviews()

        self.imageView.tintColor = Color.white.color
        self.addSubview(self.imageView)
        self.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = self.height - 20
        self.imageView.pin(.top)
        self.imageView.centerOnX()

        self.label.setSize(withWidth: self.width)
        self.label.match(.top, to: .bottom, of: self.imageView, offset: 4)
        self.label.centerOnX()
    }

    func set(text: Localized) {
        self.label.setText(text)
        self.layoutNow()
    }
}
