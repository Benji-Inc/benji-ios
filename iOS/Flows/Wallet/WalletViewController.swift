//
//  WalletViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletViewController: DiffableCollectionViewController<WalletCollectionViewDataSource.SectionType,
                            WalletCollectionViewDataSource.ItemType,
                            WalletCollectionViewDataSource> {
    
    private lazy var refreshControl: UIRefreshControl = {
        let action = UIAction { _ in
            switch self.dataSource.segmentIndex {
            case .you:
                self.loadCurrentTransactions()
            case .connections:
                self.loadConnectionsTransactions()
            }
        }
        let control = UIRefreshControl(frame: .zero, primaryAction: action)
        control.tintColor = ThemeColor.D1.color
        return control
    }()
    
    init() {
        super.init(with: WalletCollectionView())
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
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.set(backgroundColor: .B0)
        
        self.loadInitialData()
        
        self.collectionView.refreshControl = self.refreshControl
    }
    
    override func collectionViewDataWasLoaded() {
        self.dataSource.$segmentIndex
            .removeDuplicates()
            .mainSink { index in
                switch index {
                case .you:
                    self.loadCurrentTransactions()
                case .connections:
                    self.loadConnectionsTransactions()
                }
            }.store(in: &self.cancellables)
    }

    // MARK: Data Loading

    override func getAllSections() -> [WalletCollectionViewDataSource.SectionType] {
        return WalletCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] {

        var data: [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] = [:]

        guard let transactions = try? await Transaction.fetchAllCurrentTransactions() else { return data }

        data[.transactions] = transactions.compactMap({ transaction in
            return .transaction(transaction)
        })

        return data
    }
    
    private func loadCurrentTransactions() {
        Task {
            guard let transactions = try? await Transaction.fetchAllCurrentTransactions() else { return }
            await self.load(transactions: transactions)
        }.add(to: self.taskPool)
    }
    
    private func loadConnectionsTransactions() {
        Task {
            guard let transactions = try? await Transaction.fetchAllConnectionsTransactions() else {
                await self.dataSource.deleteAllItems()
                return
            }
            
            await self.load(transactions: transactions)
        }.add(to: self.taskPool)
    }
    
    private func load(transactions: [Transaction]) async {
        let items = transactions.map { transaction in
            return WalletCollectionViewDataSource.ItemType.transaction(transaction)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .transactions)
        await self.dataSource.apply(snapshot)
        Task.onMainActor {
            self.refreshControl.endRefreshing()
        }
    }
}
