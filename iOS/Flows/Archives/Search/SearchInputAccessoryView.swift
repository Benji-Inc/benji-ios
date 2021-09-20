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
        var newSize = self.bounds.size

        newSize.height = 60
        newSize.width = 300

        return newSize
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .red)
        self.addSubview(self.searchBar)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.searchBar.expandToSuperviewSize()
    }
}
