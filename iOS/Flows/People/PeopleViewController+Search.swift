//
//  PeopleViewController+Search.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension PeopleViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.performQuery(with: searchText)
    }
    
    func performQuery(with filter: String?) {
//        let mountains = mountainsController.filteredMountains(with: filter).sorted { $0.name < $1.name }
//
//        var snapshot = NSDiffableDataSourceSnapshot<Section, MountainsController.Mountain>()
//        //snapshot.appendSections([.main])
//        snapshot.appendItems(mountains)
//        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
}
