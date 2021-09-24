//
//  NewConversationCollectionViewManger.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PeopleCollectionViewManager: old_CollectionViewManager<PeopleCollectionViewManager.SectionType> {

    enum SectionType: Int, old_ManagerSectionType, CaseIterable {
        case users
    }

    private var connections: [Connection] = []

    private let connectionConfig = ManageableCellRegistration<ConnectionCell>().provider
    private let headerConfig = UICollectionView.SupplementaryRegistration
    <NewConversationHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in }

    var didLoadSnapshot: CompletionOptional = nil 

    override func initializeManager() {
        super.initializeManager()

        self.allowMultipleSelection = true 

        self.collectionView.animationView.play()

        Task {
            await self.getAllConnections()
        }
    }

    private func getAllConnections() async {
        do {
            let connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: [])
            self.connections = connections.filter { (connection) -> Bool in
                return !connection.nonMeUser.isNil
            }
            await self.loadSnapshot()
        } catch {
            print(error)
        }

        #warning("Move this to use Statusable.")
        self.collectionView.animationView.stop()
    }

    override func getSections() -> [SectionType] {
        return SectionType.allCases
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return self.connections
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.connectionConfig, for: indexPath, item: item as? Connection)
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
