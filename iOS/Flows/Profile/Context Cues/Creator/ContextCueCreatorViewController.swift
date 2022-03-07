//
//  ContextCueCreatorViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization

class ContextCueCreatorViewController: DiffableCollectionViewController<EmojiCollectionViewDataSource.SectionType,
                                       EmojiCollectionViewDataSource.ItemType,
                                       EmojiCollectionViewDataSource> {
    
    private let header = ContextCueInputHeaderView()
    
    private let segmentControl = EmojiCategorySegmentControl()
    
    let button = ThemeButton()
    private var showButton: Bool = true
    
    private let segmentGradientView = GradientView(with: [ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.cgColor,
                                                         ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    var didCreateContextCue: CompletionOptional = nil
        
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
        self.view.addSubview(self.button)
        
        self.view.addSubview(self.segmentControl)
        self.view.insertSubview(self.segmentGradientView, belowSubview: self.segmentControl)
        
        self.segmentControl.didSelectCategory = { [unowned self] category in
            self.loadEmojis(for: category)
        }
        
        self.collectionView.allowsMultipleSelection = true
        
        self.$selectedItems
            .removeDuplicates()
            .mainSink { [unowned self] items in
                self.updateButton()
            }.store(in: &self.cancellables)
        
        self.button.didSelect { [unowned self] in
            Task {
                try await self.createContextCue()
                self.didCreateContextCue?()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentControl.selectedSegmentIndex = 0
        self.loadEmojis(for: .smiles)
    }
    
    override func viewDidLayoutSubviews() {
        
        self.header.expandToSuperviewWidth()
        self.header.height = 0
        self.header.pinToSafeAreaTop()
        
        super.viewDidLayoutSubviews()
        
        self.segmentControl.sizeToFit()
        self.segmentControl.centerOnX()
        self.segmentControl.pinToSafeAreaTop()
        
        self.segmentGradientView.expandToSuperviewWidth()
        self.segmentGradientView.pin(.top)
        self.segmentGradientView.height = self.segmentControl.bottom + Theme.ContentOffset.standard.value
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.expandToSuperviewWidth()
        self.collectionView.match(.top, to: .bottom, of: self.header)
        self.collectionView.height = self.view.height - self.header.bottom
        self.collectionView.centerOnX()
    }
    
    override func getAllSections() -> [EmojiCollectionViewDataSource.SectionType] {
        return EmojiCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [EmojiCollectionViewDataSource.SectionType : [EmojiCollectionViewDataSource.ItemType]] {
        return [:]
    }
    
    private func updateButton() {
        self.button.set(style: .custom(color: .B5, textColor: .T4, text: self.getButtonTitle()))
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.showButton = self.selectedItems.count > 0
            self.view.layoutNow()
        }
    }
    
    private func getButtonTitle() -> Localized {
        let emojis: [Emoji] = self.selectedItems.compactMap { type in
            switch type {
            case .emoji(let emoji):
                return emoji
            }
        }
        
        var emojiText = ""
        let max: Int = 3
        for (index, value) in emojis.enumerated() {
            if index <= max - 1 {
                emojiText.append(contentsOf: value.emoji)
            }
        }
        
        if emojis.count > max {
            let amount = emojis.count - max
            emojiText.append(contentsOf: " +\(amount)")
        }
        
        return "Add: \(emojiText)"
    }
    
    /// The currently running task that is loading conversations.
    private var loadEmojisTask: Task<Void, Never>?
    
    private func loadEmojis(for category: EmojiCategorySegmentControl.EmojiCategory) {
        self.loadEmojisTask?.cancel()
        
        self.loadEmojisTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let emojis = try? await EmojiServiceManager.fetchEmojis(for: category) else { return }
            
            let items: [EmojiCollectionViewDataSource.ItemType] = emojis.results.compactMap({ emoji in
                return .emoji(emoji)
            })
            
            guard !Task.isCancelled else { return }
            
            var snapshot = self.dataSource.snapshot()
            snapshot.setItems([], in: .emojis)
            snapshot.setItems(items, in: .emojis)
            
            await self.dataSource.apply(snapshot)
        }
    }
    
    private func createContextCue() async throws {
        
        await self.button.handleEvent(status: .loading)
        
        let emojis: [String] = self.selectedItems.compactMap { type in
            switch type {
            case .emoji(let emoji):
                return emoji.emoji
            }
        }
        
        let contextCue = ContextCue()
        contextCue.emojis = emojis
        contextCue.owner = User.current()
        
        guard let saved = try? await contextCue.saveToServer() else {
            await self.button.handleEvent(status: .complete)
            return
        }
        
        User.current()?.latestContextCue = saved
        try await User.current()?.saveToServer()
        
        await self.button.handleEvent(status: .complete)
        
        await ToastScheduler.shared.schedule(toastType: .newContextCue(saved))
        
        AnalyticsManager.shared.trackEvent(type: .contextCueCreated, properties: ["value": saved.emojiString])
    }
}
