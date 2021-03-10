//
//  NewChannelCollectionViewManger.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class NewChannelCollectionViewManger: CollectionViewManager<NewChannelCollectionViewManger.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case users
    }

    private var connections: [Connection] = []

    private let userConfig = ManageableCellRegistration<UserCell>().cellProvider
    private let headerConfig = UICollectionView.SupplementaryRegistration
    <NewChannelHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in }

    var didLoadSnapshot: CompletionOptional = nil 

    override func initialize() {
        super.initialize()

        self.allowMultipleSelection = true 

        self.collectionView.animationView.play()
        GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { result in
                switch result {
                case .success(let connections):
                    self.connections = connections.filter { (connection) -> Bool in
                        return !connection.nonMeUser.isNil
                    }
                    self.loadSnapshot()
                case .error(_):
                    break
                }
                self.collectionView.animationView.stop()
            }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return self.connections
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.userConfig, for: indexPath, item: item as? Connection)
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.width, height: 80)
    }

    override func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        return self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.width, height: 120)
    }
}
