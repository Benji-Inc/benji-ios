//
//  ArchiveViewController+Search.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension ArchiveViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        Task {
            await self.loadData(with: self.initialQuery)
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.dataSource.deleteAllItems()
        // Show categories
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.loadQuery(with: searchText)
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {

    }

    private func loadQuery(with searchText: String) {
//        let userID = User.current()!.userObjectID!
//        let query = ChannelListQuery(filter: .containMembers(userIds: [userID]),
//                                     sort: [.init(key: .lastMessageAt, isAscending: false)],
//                                     pageSize: 20)
//
//        //let q = ChannelMemberListQuery
//
//        Task {
//            await self.loadData(with: query)
//        }
    }
}
