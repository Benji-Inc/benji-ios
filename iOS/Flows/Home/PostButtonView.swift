//
//  PostButton.swift
//  Ours
//
//  Created by Benji Dodgson on 3/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostButtonView: View {

    let button = Button()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: ""))
        self.set(backgroundColor: .clear)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.squaredSize = self.height
        self.button.centerOnXAndY()
        self.button.makeRound()
    }
}
