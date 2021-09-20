//
//  SearchInputAccessoryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SearchInputAccessoryView: View {

    private let searchBar = UISearchBar()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 100)
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .red)
        self.addSubview(self.searchBar)

        self.setupConstraits()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.searchBar.expandToSuperviewSize()
    }

    private func setupConstraits() {

    }
}
