//
//  WalletViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletViewController: DiffableCollectionViewController<WalletCollectionViewDataSource.SectionType, WalletCollectionViewDataSource.ItemType, WalletCollectionViewDataSource> {
    
    private let backgroundView = BackgroundGradientView()

    override func loadView() {
        self.view = self.backgroundView
    }
    
    init() {
        super.init(with: WelcomeCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(collectionView: UICollectionView) {
        fatalError("init(collectionView:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
    }

    // MARK: Data Loading

    override func getAllSections() -> [WalletCollectionViewDataSource.SectionType] {
        return WalletCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] {

        var data: [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] = [:]

//        if let connections = try? await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter({ (connection) -> Bool in
//            return !connection.nonMeUser.isNil
//        }), let _ = try? await connections.asyncMap({ connection in
//            return try await connection.nonMeUser!.retrieveDataIfNeeded()
//        }) {
//            let connectedPeople = connections.map { connection in
//                return Person(withConnection: connection)
//            }
//
//            self.allPeople.append(contentsOf: connectedPeople)
//        }
//
//        data[.people] = self.allPeople.compactMap({ person in
//            return .person(person)
//        })

        return data
    }
}
