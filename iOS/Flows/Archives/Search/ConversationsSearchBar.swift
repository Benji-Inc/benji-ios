//
//  ConversationSearchBar.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationsSearchBar: UISearchBar {
    
    init() {
        super.init(frame: .zero)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {
        self.searchBarStyle = .minimal
        self.isTranslucent = true
        self.backgroundColor = .clear
        self.backgroundImage = UIImage()
    }
}
