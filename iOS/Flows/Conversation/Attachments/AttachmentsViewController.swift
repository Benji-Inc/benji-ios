//
//  AttachmentsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentsViewController: DiffableCollectionViewController<AttachementsCollectionViewDataSource.SectionType,
                                 AttachementsCollectionViewDataSource.ItemType,
                                 AttachementsCollectionViewDataSource> {
    
    @Published var selectedAttachments: [Attachment] = []
    
    private let segmentGradientView = GradientView(with: [ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
            
    init() {
        super.init(with: AttachementsCollectionView())
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
                        
        self.view.addSubview(self.bottomGradientView)
    
        
        self.collectionView.allowsMultipleSelection = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func getAllSections() -> [AttachementsCollectionViewDataSource.SectionType] {
        return AttachementsCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [AttachementsCollectionViewDataSource.SectionType : [AttachementsCollectionViewDataSource.ItemType]] {
        return [:]
    }
}
