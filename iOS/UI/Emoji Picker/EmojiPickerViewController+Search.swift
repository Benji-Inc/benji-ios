//
//  EmojiPickerViewController+Search.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension EmojiPickerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.performQuery(with: searchText)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let category = EmojiCategory.init(rawValue: selectedScope) else { return }
        self.loadEmojis(for: category)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsScope(false, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsScope(true, animated: true)
        searchBar.selectedScopeButtonIndex = 0
    }
    
    func performQuery(with filter: String?) {
        guard let text = filter,
                !text.isEmpty || !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        
        let filtered: [EmojiCollectionViewDataSource.ItemType] = self.filtered(emojis: EmojiCategory.allEmojis, filter: filter).map { emoji in
            return .emoji(emoji)
        }

        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(filtered, in: .emojis)
        self.dataSource.apply(snapshot)
    }
    
    func filtered(emojis: [Emoji], filter: String? = nil, limit: Int? = nil) -> [Emoji] {

        return emojis.filter { emoji in
            emoji.contains(filter) && !self.selectedEmojis.contains(emoji)
        }
    }
}
