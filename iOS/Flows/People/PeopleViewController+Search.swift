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
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        var snapshot = self.dataSource.snapshot()
        let items: [PeopleCollectionViewDataSource.ItemType] = self.allPeople.sorted().map { person in
            var copy = person
            copy.isSelected = self.selectedPeople.contains(where: { current in
                return current.personId == person.personId
            })
            return .person(copy)
        }
        
        snapshot.setItems(items, in: .people)
        self.dataSource.apply(snapshot)
    }
    
    func performQuery(with filter: String?) {
        
        let filtered: [PeopleCollectionViewDataSource.ItemType] = self.filtered(people: self.allPeople, filter: filter).sorted { lhs, rhs in
            lhs.familyName < rhs.familyName
        }.map { person in
            var copy = person
            copy.updateHighlight(text: filter)
            return .person(copy)
        }
        
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(filtered, in: .people)
        self.dataSource.apply(snapshot)
    }
    
    func filtered(people: [Person], filter: String? = nil, limit: Int? = nil) -> [Person] {
        let filtered = people.filter { person in
            person.contains(filter) && !self.selectedPeople.contains(person)
        }
        
        if let limit = limit {
            return Array(filtered.prefix(through: limit))
        } else {
            return filtered
        }
    }
}
