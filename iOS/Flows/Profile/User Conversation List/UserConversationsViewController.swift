//
//  UserConversationsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserConversationsViewController: DiffableCollectionViewController<UserConversationsDataSource.SectionType,
                                       UserConversationsDataSource.ItemType,
                                       UserConversationsDataSource> {
    
    private let segmentGradientView = GradientView(with: [ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
    private let backgroundView = BaseView()
    lazy var segmentControl = ConversationsSegmentControl()
    
    init() {
        super.init(with: CollectionView(layout: UserConversationsCollectionViewLayout()))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
                
        self.backgroundView.set(backgroundColor: .walletBackground)
        self.view.layer.cornerRadius = Theme.cornerRadius
        self.view.clipsToBounds = true
        
        self.view.insertSubview(self.backgroundView, belowSubview: self.collectionView)
        self.view.insertSubview(self.segmentControl, aboveSubview: self.collectionView)
        self.view.insertSubview(self.segmentGradientView, belowSubview: self.segmentControl)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        
        self.segmentGradientView.width = self.collectionView.width
        self.segmentGradientView.top = self.collectionView.top
        self.segmentGradientView.height = padding.doubled + self.segmentControl.height
        self.segmentGradientView.centerOnX()
    }
    
    override func getAllSections() -> [UserConversationsDataSource.SectionType] {
        return []
    }
    
    override func retrieveDataForSnapshot() async -> [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] {
        var data: [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] = [:]
        
        return data
    }
}
