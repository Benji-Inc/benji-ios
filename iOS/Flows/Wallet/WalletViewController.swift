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
    
    private let topGradientView
    = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                   startPoint: .topCenter,
                   endPoint: .bottomCenter)
    
    private let bottomGradientView
    = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                   startPoint: .bottomCenter,
                   endPoint: .topCenter)
    
    private let walletGradientView
    = GradientPassThroughView(with: [ThemeColor.B6.color.cgColor,
                          ThemeColor.B6.color.cgColor,
                          ThemeColor.B6.color.cgColor,
                          ThemeColor.B6.color.withAlphaComponent(0.0).cgColor],
                   startPoint: .topCenter,
                   endPoint: .bottomCenter)
    private let backgroundView = BaseView()

    lazy var header = WalletHeaderView()
    lazy var segmentControl = WalletSegmentControl()
    
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
        
        self.collectionView.allowsMultipleSelection = false 

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true 
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.addSubview(self.header)
        self.backgroundView.set(backgroundColor: .B6)
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
        
        self.backgroundView.layer.cornerRadius = Theme.cornerRadius
        self.backgroundView.clipsToBounds = true
        
        self.view.insertSubview(self.backgroundView, belowSubview: self.collectionView)
        self.view.insertSubview(self.segmentControl, aboveSubview: self.collectionView)
        self.view.insertSubview(self.walletGradientView, belowSubview: self.segmentControl)
        
        self.walletGradientView.layer.cornerRadius = Theme.cornerRadius
        self.walletGradientView.clipsToBounds = true
    }
    
    override func viewDidLayoutSubviews() {
        
        self.header.height = 240
        self.header.width = self.view.width - Theme.ContentOffset.xtraLong.value.doubled
        self.header.pin(.top)
        self.header.centerOnX()
        
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = 34
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
        
        let padding = Theme.ContentOffset.xtraLong.value
        let totalWidth = self.collectionView.width - padding.doubled
        let segmentWidth = totalWidth * 0.3333
        self.segmentControl.sizeToFit()
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 0)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 1)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 2)

        self.segmentControl.width = self.collectionView.width - padding.doubled
        self.segmentControl.centerOnX()
        self.segmentControl.match(.top, to: .top, of: self.collectionView, offset: .xtraLong)
        
        self.backgroundView.frame = self.collectionView.frame
        self.backgroundView.height = self.collectionView.height + 100
        
        self.walletGradientView.width = self.collectionView.width
        self.walletGradientView.top = self.collectionView.top
        self.walletGradientView.height = padding.doubled + self.segmentControl.height
        self.walletGradientView.centerOnX()
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.match(.top, to: .bottom, of: self.header)
        self.collectionView.height = self.view.height - self.header.bottom
        self.collectionView.width = self.view.width - Theme.ContentOffset.xtraLong.value.doubled
        self.collectionView.centerOnX()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentControl.didSelectSegmentIndex = { [unowned self] index in
            switch index {
            case .achievements:
                self.loadAchievements()
            case .you:
                self.loadCurrentTransactions()
            case .connections:
                self.loadConnectionsTransactions()
            }
        }
                        
        self.view.set(backgroundColor: .B0)
        self.loadInitialData()
    }

    // MARK: Data Loading

    override func getAllSections() -> [WalletCollectionViewDataSource.SectionType] {
        return WalletCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] {

        var data: [WalletCollectionViewDataSource.SectionType: [WalletCollectionViewDataSource.ItemType]] = [:]

        guard let transactions = try? await Transaction.fetchAllCurrentTransactions() else { return data }

        Task.onMainActor {
            self.header.configure(with: transactions)
        }
        
        data[.transactions] = transactions.compactMap({ transaction in
            return .transaction(transaction)
        })

        return data
    }
    
    private func loadAchievements() {
        Task { [weak self] in
            await self?.loadAchievements()
        }.add(to: self.autocancelTaskPool)
    }
    
    private func loadCurrentTransactions() {
        Task { [weak self] in
            guard let transactions = try? await Transaction.fetchAllCurrentTransactions() else { return }
            await self?.load(transactions: transactions)
        }.add(to: self.autocancelTaskPool)
    }
    
    private func loadConnectionsTransactions() {
        Task { [weak self] in
            guard let transactions = try? await Transaction.fetchAllConnectionsTransactions() else {
                await self?.dataSource.deleteAllItems()
                return
            }
            
            await self?.load(transactions: transactions)
        }.add(to: self.autocancelTaskPool)
    }
    
    private func loadAchievements() async {
        
        let achievements = AchievementsManager.shared.achievements
        let types = AchievementsManager.shared.types
        
        let items: [WalletCollectionViewDataSource.ItemType] = types.map { type in
            
            let selected = achievements.filter { achievement in
                return achievement.type == type
            }
            
            return AchievementViewModel(type: type, achievements: selected)
        }.sorted { lhs, rhs in
            return lhs.count > rhs.count
        }.compactMap { model in
            return .achievement(model)
        }
        
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .achievements)
        snapshot.setItems([], in: .transactions)
        await self.dataSource.apply(snapshot)
    }
    
    private func load(transactions: [Transaction]) async {
        let items = transactions.map { transaction in
            return WalletCollectionViewDataSource.ItemType.transaction(transaction)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems([], in: .achievements)
        snapshot.setItems(items, in: .transactions)
        await self.dataSource.apply(snapshot)
    }
}
