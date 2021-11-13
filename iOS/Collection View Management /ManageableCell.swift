//
//  ManageableCell.swift
//  Benji
//
//  Created by Benji Dodgson on 11/9/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol ManageableCell: AnyObject {
    /// The type that will be used to configure this object.
    associatedtype ItemType: Hashable

    /// Conforming types should take in the item type and set up the cell's visual state.
    func configure(with item: ItemType)

    /// Called with a managing objects selectedIndexPaths is set
    func update(isSelected: Bool)

    var currentItem: Self.ItemType? { get set }
}

