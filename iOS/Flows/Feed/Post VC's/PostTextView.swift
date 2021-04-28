//
//  FeedTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class PostTextView: TextView {

    override func initializeViews() {
        super.initializeViews()

        self.isScrollEnabled = false 
    }

    func set(localizedText: Localized) {

        let attributed = AttributedString(localizedText,
                                          fontType: .regular,
                                          color: .white)

        self.set(attributed: attributed,
                 alignment: .center,
                 linkColor: .teal)
    }
}
