//
//  CollectionViewManagerCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import UIKit

struct ManageableCellRegistration<Cell: UICollectionViewCell & ManageableCell> {
    let provider = UICollectionView.CellRegistration<Cell, Cell.ItemType> { (cell, indexPath, model)  in
        cell.configure(with: model)
        cell.update(isSelected: cell.isSelected)
        cell.currentItem = model
    }
}

struct ManageableFooterRegistration<Footer: UICollectionReusableView> {
    let provider = UICollectionView.SupplementaryRegistration<Footer>(elementKind: UICollectionView.elementKindSectionFooter) { footerView, elementKind, indexPath in }
}

struct ManageableHeaderRegistration<Header: UICollectionReusableView> {
    let provider = UICollectionView.SupplementaryRegistration<Header>(elementKind: UICollectionView.elementKindSectionHeader) { headerView, elementKind, indexPath in }
}

protocol ElementKind {
    static var kind: String { get set }
}

struct ManageableSupplementaryViewRegistration<View: UICollectionReusableView & ElementKind> {
    let provider = UICollectionView.SupplementaryRegistration<View>(elementKind: View.kind) { headerView, elementKind, indexPath in }
}

// A base class that other cells managed by a CollectionViewManager can inherit from.
class CollectionViewManagerCell: UICollectionViewListCell {

    var cancellables = Set<AnyCancellable>()
    var taskPool = TaskPool()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeSubviews()
    }

    func initializeSubviews() {}

    func update(isSelected: Bool) {
        guard isSelected != self.isSelected else { return }
    }

    func reset() {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        // Get the system default background configuration for a plain style list cell in the current state.
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell().updated(for: state)

        // Customize the background color to be clear, no matter the state.
        backgroundConfig.backgroundColor = ThemeColor.clear.color

        // Apply the background configuration to the cell.
        self.backgroundConfiguration = backgroundConfig
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        Task {
            await self.taskPool.cancelAndRemoveAll()
        }
    }
}
