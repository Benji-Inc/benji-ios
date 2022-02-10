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
    
    private let topGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                               startPoint: .topCenter,
                                               endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
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
        
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = 34
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        self.view.set(backgroundColor: .B0)
        
        self.loadInitialData()
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
    }
}
