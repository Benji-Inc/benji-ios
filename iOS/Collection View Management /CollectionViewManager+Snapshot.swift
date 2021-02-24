//
//  CollectionViewManger+Snapshot.swift
//  Ours
//
//  Created by Benji Dodgson on 2/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension CollectionViewManager {

    func reloadAllSections(animate: Bool = true) {
        if self.dataSource.numberOfSections(in: self.collectionView) == 0 {
            self.loadSnapshot()
        } else {
            var new = self.dataSource.snapshot()
            new.reloadSections(SectionType.allCases as! [SectionType])
            self.dataSource.apply(new, animatingDifferences: true)
        }
    }

    func append(items: [AnyHashable], to section: SectionType, animate: Bool = true) {
        // Crashes on connection request
        if self.dataSource.snapshot().sectionIdentifiers.contains(section) {
            var new = self.dataSource.snapshot()
            new.appendItems(items, toSection: section)
            self.dataSource.apply(new, animatingDifferences: animate)
        } else {
            var new = self.dataSource.snapshot()
            new.appendSections([section])
            new.appendItems(items, toSection: section)
            self.dataSource.apply(new, animatingDifferences: animate)
        }
    }

    func insert(items: [AnyHashable], before item: AnyHashable, animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.insertItems(items, beforeItem: item)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func insert(items: [AnyHashable], after item: AnyHashable, animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.insertItems(items, afterItem: item)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func delete(items: [AnyHashable], animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.deleteItems(items)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func deleteAllItems(animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.deleteAllItems()
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func move(item: AnyHashable, beforeItem: AnyHashable, animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.moveItem(item, beforeItem: beforeItem)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func move(item: AnyHashable, afterItem: AnyHashable, animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.moveItem(item, afterItem: afterItem)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func reload(items: [AnyHashable], animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.reloadItems(items)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func append(sections: [SectionType], animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.appendSections(sections)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func delete(sections: [SectionType], animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.deleteSections(sections)
        self.dataSource.apply(new, animatingDifferences: animate)
    }

    func reload(sections: [SectionType], animate: Bool = true) {
        var new = self.dataSource.snapshot()
        new.reloadSections(sections)
        self.dataSource.apply(new, animatingDifferences: animate)
    }
}
