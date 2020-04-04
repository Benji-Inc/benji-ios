//
//  InvitesCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ReactiveSwift

class InvitesCollectionViewManager: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    unowned let collectionView: CollectionView

    let items = MutableProperty<[Inviteable]>([])

    var allowMultipleSelection: Bool = false

    private(set) var oldSelectedIndexPaths: Set<IndexPath> = []
    private(set) var selectedIndexPaths: Set<IndexPath> = [] {
        didSet {
            self.oldSelectedIndexPaths = oldValue
        }
    }

    var selectedItems: [Inviteable] {
        var items: [Inviteable] = []
        for indexPath in self.selectedIndexPaths {
            if let item = self.items.value[safe: indexPath.row] {
                items.append(item)
            }
        }
        return items
    }

    // MARK: Events

    lazy var onSelectedItem = Property(self._onSelectedItem)
    private let _onSelectedItem = MutableProperty<(item: Inviteable, indexPath: IndexPath)?>(nil)
    var didLongPress: ((Inviteable, IndexPath) -> Void)?
    var willDisplayCell: ((Inviteable, IndexPath) -> Void)?
    var didFinishCenteringOnCell: ((Inviteable, IndexPath) -> Void)?

    required init(with collectionView: CollectionView) {
        self.collectionView = collectionView

        super.init()

        self.initializeCollectionView()
    }

    func initializeCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }

    // MARK: CollectionView Data Source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.value.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let invitesCollectionView = collectionView as? InvitesCollectionView else { return UICollectionViewCell() }

        switch indexPath.section {
        case 0:
            return self.getPendingConnectionCell(for: indexPath, collectionView: invitesCollectionView)
        case 1:
            return self.getContacsCell(for: indexPath, collectionView: invitesCollectionView)
        default:
            fatalError()
        }

//        let cell: CellType = collectionView.dequeueReusableCell(withReuseIdentifier: CellType.reuseID,
//                                                                for: indexPath) as! CellType
//
//        let item = self.items.value[safe: indexPath.row]
//        cell.configure(with: item)
//
//        cell.onLongPress = { [unowned self] in
//            guard let item = self.items.value[safe: indexPath.row] else { return }
//            self.didLongPress?(item, indexPath)
//        }
//
//        // Allows subclasses to do additional cell configuration
//        self.managerDidConfigure(cell: cell, for: indexPath)
    }

    private func getPendingConnectionCell(for indexPath: IndexPath, collectionView: InvitesCollectionView) -> PendingConnectionCell {
        let cell = collectionView.dequeueReusableCell(PendingConnectionCell.self, for: indexPath)
        return cell
    }

    private func getContacsCell(for indexPath: IndexPath, collectionView: InvitesCollectionView) -> ContactCell {
        let cell = collectionView.dequeueReusableCell(ContactCell.self, for: indexPath)
        return cell
    }

    // Subclasses can override this to do more cell configuration
    func managerDidConfigure(cell: Inviteable, for indexPath: IndexPath) {
        //cell.update(isSelected: self.selectedIndexPaths.contains(indexPath))
    }

    // MARK: CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //self.select(indexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.width, height: 90)
    }
    
}
