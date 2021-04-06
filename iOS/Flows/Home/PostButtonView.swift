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
        self.set(backgroundColor: .clear)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.height = self.height
        self.button.centerOnXAndY()
    }

    func update(for state: HomeTabView.State) {

        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .home:
                self.button.set(style: .icon(image: UIImage(systemName: "plus")!, color: .white))
                self.button.width = self.height
                self.button.makeRound()
            case .post:
                self.button.set(style: .normal(color: .white, text: ""))
                self.button.width = self.height
                self.button.makeRound()
            case .confirm:
                self.button.set(style: .normal(color: .purple, text: "post"), alpha: 0.8)
                self.button.expandToSuperviewWidth()
                self.button.roundCorners()
            }

            self.layoutNow()
        }
    }
}
