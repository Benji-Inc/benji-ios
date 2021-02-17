//
//  NewChannelViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewChannelViewController: CollectionViewController<NewChannelCollectionViewManger.SectionType, NewChannelCollectionViewManger> {

    var didCreateChannel: CompletionOptional = nil

    private let createButton = Button()

    init() {
        super.init(with: NewChannelCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.$onSelectedItem.mainSink { _ in
            self.createButton.isEnabled = self.collectionViewManager.selectedItems.count > 0
        }.store(in: &self.cancellables)

        self.view.insertSubview(self.createButton, aboveSubview: self.collectionView)
        self.createButton.set(style: .normal(color: .purple, text: "Create"))
        self.createButton.didSelect { [unowned self] in
            self.createChannel()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.createButton.setSize(with: self.view.width)
        self.createButton.pinToSafeArea(.bottom, padding: 0)
        self.createButton.centerOnX()
    }

    func createChannel() {
        // Create the channel
    }
}
