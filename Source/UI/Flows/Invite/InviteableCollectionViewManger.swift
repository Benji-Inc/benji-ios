//
//  InviteableCollectionViewManger.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InviteableCollectionViewManger: CollectionViewManager<InviteableCell> {

    private let selectionImpact = UIImpactFeedbackGenerator(style: .light)

    lazy var allCache: [Inviteable] = []

    var contactFilter: SearchFilter? {
        didSet {
            self.loadFilteredContacts()
        }
    }

    func loadFilteredContacts() {
        guard let filter = self.contactFilter else { return }

        var filtered: [Inviteable] = []

        filtered = self.allCache.filter({ (inviteable) -> Bool in
            if let _ = inviteable.fullName.range(of: filter.text, options: .caseInsensitive) {
                return true
            } else {
                return false
            }
        })

        self.set(newItems: filtered) { (_) in }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.items.value[safe: indexPath.row], case Inviteable.contact(_, let status) = item, status == .pending else { return }

        super.collectionView(collectionView, didSelectItemAt: indexPath)

        self.selectionImpact.impactOccurred()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.width, height: 90)
    }
}
