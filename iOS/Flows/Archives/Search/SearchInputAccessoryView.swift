//
//  SearchInputAccessoryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SearchInputAccessoryView: View {

    let searchBar = ConversationsSearchBar()

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 100)
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.set(backgroundColor: .clear)
        self.addSubview(self.blurView)
        self.blurView.roundCorners()

        self.addSubview(self.searchBar)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.width = self.width - Theme.contentOffset
        self.blurView.centerOnX()
        self.blurView.height = 60
        self.blurView.pin(.top, padding: 10)

        self.searchBar.width = self.width - Theme.contentOffset
        self.searchBar.centerOnX()
        self.searchBar.height = 80
        self.searchBar.pin(.top)
    }
}
