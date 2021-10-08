//
//  CollectionViewManagerCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

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
    let provider = UICollectionView.SupplementaryRegistration<Header>(elementKind: UICollectionView.elementKindSectionHeader) { footerView, elementKind, indexPath in }
}

// A base class that other cells managed by a CollectionViewManager can inherit from.
class CollectionViewManagerCell: UICollectionViewListCell {

    var onLongPress: (() -> Void)?
    var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {

        super.init(frame: frame)
        self.initializeLongPressGesture()
        self.initializeSubviews()
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        self.initializeLongPressGesture()
        self.initializeSubviews()
    }

    func initializeSubviews() {}

    private func initializeLongPressGesture() {

        let longPress = UILongPressGestureRecognizer { [unowned self] (longPress) in
            switch longPress.state {
            case .possible, .changed:
                break
            case .began:
                self.onLongPress?()
                // If the user starts a long press, we don't want this cell to be selected.
                // Cancelling touches in this view means only a long press event will occur.
                longPress.cancelsTouchesInView = true
            case .ended, .cancelled, .failed:
                longPress.cancelsTouchesInView = false
            @unknown default:
                break
            }
        }
        // Don't cancel other touches so we don't interfere with the default cell selection behavior
        longPress.cancelsTouchesInView = false
        self.contentView.addGestureRecognizer(longPress)
    }

    func update(isSelected: Bool) {}

    func reset() {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        // Get the system default background configuration for a plain style list cell in the current state.
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell().updated(for: state)

        // Customize the background color to be clear, no matter the state.
        backgroundConfig.backgroundColor = Color.clear.color

        // Apply the background configuration to the cell.
        self.backgroundConfiguration = backgroundConfig
    }
}
