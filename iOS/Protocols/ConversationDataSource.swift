//
//  ConversationDataSource.swift
//  Benji
//
//  Created by Benji Dodgson on 7/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

protocol ConversationDataSource: AnyObject {

    var numberOfMembers: Int { get set }
    var sections: [ConversationSectionable] { get set }
    var collectionView: ConversationThreadCollectionView { get set }

    func item(at indexPath: IndexPath) -> Messageable?
    func numberOfSections() -> Int
    func numberOfItems(inSection section: Int) -> Int

    func reset()
    func set(newSections: [ConversationSectionable],
             keepOffset: Bool,
             animate: Bool,
             completion: CompletionOptional)
    func append(item: Messageable, completion: CompletionOptional)
    @MainActor
    func append(item: Messageable) async
    func updateItemSync(with updatedItem: Messageable,
                        replaceTypingIndicator: Bool,
                        completion: CompletionOptional)
    func delete(item: Messageable, in section: Int)
}

extension ConversationDataSource {

    func item(at indexPath: IndexPath) -> Messageable? {
        guard let section = self.sections[safe: indexPath.section],
              let item = section.items[safe: indexPath.row] else { return nil }

        return item
    }

    func numberOfSections() -> Int {
        return self.sections.count
    }

    func numberOfItems(inSection section: Int) -> Int {
        guard let section = self.sections[safe: section] else { return 0 }
        return section.items.count
    }

    func reset() {
        self.sections = []
        self.collectionView.reloadData()
    }

    func set(newSections: [ConversationSectionable],
             keepOffset: Bool = false,
             animate: Bool = false,
             completion: CompletionOptional) {

        if animate {
            self.collectionView.alpha = 0
            self.sections = newSections
            if keepOffset {
                self.collectionView.reloadDataAndKeepOffset()
            } else {
                self.collectionView.reloadData()
            }

            self.animateIn(completion: completion)
        } else {
            self.sections = newSections
            if keepOffset {
                self.collectionView.reloadDataAndKeepOffset()
                completion?()
            } else {
                self.collectionView.reloadData()
                completion?()
            }
        }
    }

    func append(item: Messageable, completion: CompletionOptional) {
        var sectionIndex: Int?
        var itemCount: Int?

        for (index, type) in self.sections.enumerated() {
            if type.date.isSameDay(as: item.createdAt) {
                sectionIndex = index
                itemCount = type.items.count
            }
        }

        if let count = itemCount, let section = sectionIndex {
            let indexPath = IndexPath(item: count, section: section)

            self.sections[section].items.append(item)
            self.collectionView.insertItems(at: [indexPath])
            completion?()
        } else {
            //Create new section
            let new = ConversationSectionable(date: item.createdAt, items: [item])
            self.sections.append(new)
            self.collectionView.reloadData()
            completion?()
        }
    }

    @MainActor
    func append(item: Messageable) async {
        var sectionIndex: Int?
        var itemCount: Int?

        for (index, type) in self.sections.enumerated() {
            if type.date.isSameDay(as: item.createdAt) {
                sectionIndex = index
                itemCount = type.items.count
            }
        }

        if let count = itemCount, let section = sectionIndex {
            let indexPath = IndexPath(item: count, section: section)

            self.sections[section].items.append(item)
            self.collectionView.insertItems(at: [indexPath])
        } else {
            //Create new section
            let new = ConversationSectionable(date: item.createdAt, items: [item])
            self.sections.append(new)
            self.collectionView.reloadData()
        }
    }

    func updateItemSync(with updatedItem: Messageable,
                        replaceTypingIndicator: Bool = false,
                        completion: CompletionOptional = nil) {

        // If there is no update id and it's from the current user,
        // then we've already displayed this message and can safely return.
        if updatedItem.updateId == nil && updatedItem.isFromCurrentUser {
            return
        }

        var indexPath: IndexPath? = nil

        // If the new message matches an existing message's id, then replace the old one.
        if let updateId = updatedItem.updateId {
            for (sectionIndex, section) in self.sections.enumerated() {
                for (itemIndex, item) in section.items.enumerated() {
                    print("ID \(item.updateId ?? "NONE")")
                    if item.updateId == updateId {
                        indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                        break
                    }
                }
            }
        }

        // If the new message isn't replacing an old one, append it to the end.
        if indexPath.isNil {
            if replaceTypingIndicator, let lastSection = self.sections.last {
                let section = self.sections.count - 1
                indexPath = IndexPath(item: lastSection.items.count - 1, section: section)
            } else {
                self.append(item: updatedItem, completion: completion)
            }
        }

        guard let ip = indexPath else { return }

        self.sections[ip.section].items[ip.row] = updatedItem
        self.collectionView.reloadItems(at: [ip])
        completion?()
    }

    @MainActor
    func updateItem(with updatedItem: Messageable, replaceTypingIndicator: Bool = false) async {

        // If there is no update id and it's from the current user,
        // then we've already displayed this message and can safely return.
        if updatedItem.updateId == nil && updatedItem.isFromCurrentUser {
            return
        }

        var indexPath: IndexPath? = nil

        // If the new message matches an existing message's id, then replace the old one.
        if let updateId = updatedItem.updateId {
            for (sectionIndex, section) in self.sections.enumerated() {
                for (itemIndex, item) in section.items.enumerated() {
                    print("ID \(item.updateId ?? "NONE")")
                    if item.updateId == updateId {
                        indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                        break
                    }
                }
            }
        }

        // If the new message isn't replacing an old one, append it to the end.
        if indexPath.isNil {
            if replaceTypingIndicator, let lastSection = self.sections.last {
                let section = self.sections.count - 1
                indexPath = IndexPath(item: lastSection.items.count - 1, section: section)
            } else {
                await self.append(item: updatedItem)
                return
            }
        }

        guard let indexPath = indexPath else { return }
        
        self.sections[indexPath.section].items[indexPath.row] = updatedItem
        self.collectionView.reloadItems(at: [indexPath])
    }
    
    func delete(item: Messageable, in section: Int = 0) {

        guard let sectionValue = self.sections[safe: section] else { return }

        var indexPath: IndexPath?

        for (index, existingItem) in sectionValue.items.enumerated() {
            if existingItem == item {
                indexPath = IndexPath(item: index, section: section)
                break
            }
        }

        guard let ip = indexPath else { return }

        self.sections[section].items.remove(at: ip.row)
        self.collectionView.deleteItems(at: [ip])
    }
}
