//
//  NSDiffableDataSourceSnapShot+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 9/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension NSDiffableDataSourceSnapshot {

    /// Inserts the given items into the section starting at the given index. If the index is is greater than the number of items in the section,
    /// then the new items are appended to the section.
    mutating func insertItems(_ identifiers: [ItemIdentifierType],
                              in section: SectionIdentifierType,
                              atIndex index: Int) {

        let itemsInSection = self.itemIdentifiers(inSection: section)
        if let itemAtIndex = itemsInSection[safe: index] {
            self.insertItems(identifiers, beforeItem: itemAtIndex)
        } else {
            self.appendItems(identifiers, toSection: section)
        }
    }

    /// Reloads the item contained in the specified section at that section's specified index.
    /// If no item exists at that index, this function does nothing.
    mutating func reloadItem(atIndex index: Int, in section: SectionIdentifierType) {
        let itemsInSection = self.itemIdentifiers(inSection: section)
        if let itemAtIndex = itemsInSection[safe: index] {
            self.reloadItems([itemAtIndex])
        }
    }

    /// Reconfigures the item contained in the specified section at that section's specified index.
    /// If no item exists at that index, this function does nothing.
    mutating func reconfigureItem(atIndex index: Int, in section: SectionIdentifierType) {
        let itemsInSection = self.itemIdentifiers(inSection: section)
        if let itemAtIndex = itemsInSection[safe: index] {
            self.reconfigureItems([itemAtIndex])
        }
    }

    func indexPathOfItem(_ identifier: ItemIdentifierType) -> IndexPath? {
        guard let indexOfItem = self.indexOfItem(identifier),
              let containingSection = self.sectionIdentifier(containingItem: identifier),
              let indexOfSection = self.indexOfSection(containingSection) else { return nil }

        return IndexPath(item: indexOfItem, section: indexOfSection)
    }
}
