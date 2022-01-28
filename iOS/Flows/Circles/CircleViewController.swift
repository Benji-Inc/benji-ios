//
//  CircleViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleViewController: DiffableCollectionViewController<CircleSectionType,
                            CircleItemType,
                            CircleCollectionViewDataSource> {
    
    let backgroundGradient = BackgroundGradientView()
    let label = ThemeLabel(font: .regular)
    let remainingLabel = ThemeLabel(font: .small)
    
    let circleNameLabel = ThemeLabel(font: .regular)
    let button = ThemeButton()
    
    let pullView = PullView()
    
    private(set) var circle: Circle
        
    init(with circle: Circle) {
        self.circle = circle 
        let cv = CollectionView(layout: CircleCollectionViewLayout())
        cv.isScrollEnabled = false
        cv.showsHorizontalScrollIndicator = false
        super.init(with: cv)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = self.backgroundGradient
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.collectionView.animationView.isHidden = true
        
        self.view.addSubview(self.label)
        self.label.setText("Add people by tapping on any empty circle.")
        self.label.textAlignment = .center
        
        self.view.addSubview(self.remainingLabel)
        self.remainingLabel.textAlignment = .center
        self.remainingLabel.alpha = 0.6
        
        self.view.addSubview(self.pullView)
        self.view.addSubview(self.circleNameLabel)
        self.view.addSubview(self.button)
        
        self.circleNameLabel.setText("Circle Name")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    func updateRemaining(with amount: Int) {
        self.remainingLabel.setText("\(amount) remaining")
        self.view.layoutNow()
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.circleNameLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.circleNameLabel.pinToSafeAreaTop()
        self.circleNameLabel.centerOnX()
        
        self.button.height = 44
        self.button.width = self.circleNameLabel.width
        self.button.center = self.circleNameLabel.center
        
        self.collectionView.width = self.view.width * 1.4
        self.collectionView.centerOnX()
        
        self.label.setSize(withWidth: self.view.halfWidth)
        self.label.centerOnXAndY()
        self.label.centerY -= 50
        
        self.remainingLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.remainingLabel.centerOnX()
        self.remainingLabel.match(.top, to: .bottom, of: self.label, offset: .standard)
        
        self.pullView.centerOnX()
        self.pullView.centerY = (self.view.height * 0.9) - 50
    }
    
    override func getAllSections() -> [CircleSectionType] {
        return [.circle]
    }
    
    override func retrieveDataForSnapshot() async -> [CircleSectionType : [CircleItemType]] {
        var data: [CircleSectionType: [CircleItemType]] = [:]
        data[.circle] = self.getAllItems()
        return data
    }
    
    func getAllItems() -> [CircleItemType] {
        
        var allItems: [CircleItemType] = []
        var itemCount: Int = 0
        
        let limit = self.circle.limit
        
        for i in 0..<limit {
            if let user = self.circle.users[safe: i] {
                allItems.append(.item(CircleItem(position: i, user: user)))
                itemCount += 1
            }
        }
        
        for i in 0..<limit {
            if let contactId = self.circle.invitedContacts[safe: i],
                      let contact = ContactsManger.shared.searchForContact(with: .identifier(contactId)).first {
                allItems.append(.item(CircleItem(position: i, contact: contact)))
                itemCount += 1
            }
        }
        
        for i in itemCount..<limit {
            allItems.append(.item(CircleItem(position: i)))
        }
        
        let remaining = self.circle.limit - itemCount
        
        self.updateRemaining(with: remaining)
        
        return allItems
    }
    
    @MainActor
    func update(with circle: Circle) {
        self.circle = circle
        self.dataSource.reconfigureItems(self.getAllItems())
    }
}
