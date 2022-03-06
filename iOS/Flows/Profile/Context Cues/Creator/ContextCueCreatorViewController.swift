//
//  ContextCueCreatorViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ContextCueCreatorViewController: DiffableCollectionViewController<EmojiCollectionViewDataSource.SectionType,
                                       EmojiCollectionViewDataSource.ItemType,
                                       EmojiCollectionViewDataSource> {
    
    private let header = ContextCueInputHeaderView()
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
        
    init() {
        super.init(with: EmojiCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.view.set(backgroundColor: .B0)
                        
        self.view.addSubview(self.header)
        self.view.addSubview(self.bottomGradientView)
        
        self.$selectedItems.mainSink { [unowned self] items in
            
            let emojis: [String] = items.compactMap { type in
                switch type {
                case .emoji(let emoji):
                    return emoji
                }
            }
            
            logDebug(emojis)
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        
        self.header.expandToSuperviewWidth()
        self.header.height = 80
        self.header.pinToSafeAreaTop()
        
        super.viewDidLayoutSubviews()
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.expandToSuperviewWidth()
        self.collectionView.match(.top, to: .bottom, of: self.header, offset: .custom(34))
        self.collectionView.height = self.view.height - self.header.bottom - 34
        self.collectionView.centerOnX()
    }
    
    override func getAllSections() -> [EmojiCollectionViewDataSource.SectionType] {
        return EmojiCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [EmojiCollectionViewDataSource.SectionType : [EmojiCollectionViewDataSource.ItemType]] {
        var data: [EmojiCollectionViewDataSource.SectionType : [EmojiCollectionViewDataSource.ItemType]] = [:]
        return data
    }
}
