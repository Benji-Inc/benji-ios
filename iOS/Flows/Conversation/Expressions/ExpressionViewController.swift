//
//  ExpressionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization

class ExpressionViewController: EmojiPickerViewController {
    
    override func initializeViews() {
        super.initializeViews()

        self.collectionView.allowsMultipleSelection = false
    }
    
    override func setupNavigationBar() {
        super.setupNavigationBar()
        
        self.navigationItem.title = "Choose Expression"
        self.navigationItem.searchController?.searchBar.scopeButtonTitles = []
    }
    
    override func getAllAvailableEmojis() -> [Emoji] {
        return EmojiCategory.smileysAndPeople.emojis
    }
}