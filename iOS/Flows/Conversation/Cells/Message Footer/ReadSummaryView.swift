//
//  ReadSummaryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReadSummaryView: BaseView, MessageConfigureable {
    
    private var controller: MessageController?
    private var readerCount: Int = 0
    
    let label = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    let readersView = ReadersView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
        
        self.addSubview(self.readersView)
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        guard let controller = JibberChatClient.shared.messageController(for: message) else { return }

        if let existing = self.controller,
            existing.messageId == controller.messageId,
           self.readerCount == controller.message?.readReactions.count {
            return
        }
                
        self.loadTask?.cancel()
                
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = controller
            
            if let controller = self.controller, !controller.hasLoadedAllReactions  {
                try? await controller.loadReactions()
            }
            
            self.readerCount = controller.message?.readReactions.count ?? 0
            
            let readers: [ReadViewModel] = self.controller?.message?.readReactions.filter({ reaction in
                return reaction.author.id != User.current()?.objectId
            }).compactMap({ reaction in
                return ReadViewModel(authorId: reaction.author.personId, createdAt: reaction.createdAt)
            }) ?? []
            
            self.readersView.configure(with: readers)
            
            self.layoutNow()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}

class ReadersView: BaseView {
        
    private let scrollView = UIScrollView()
    
    private var models: [ReadViewModel] = []
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.scrollView)
        self.scrollView.showsHorizontalScrollIndicator = false 
        self.clipsToBounds = false
        self.scrollView.clipsToBounds = false 
    }
    
    func configure(with models: [ReadViewModel]) {
        guard models != self.models else { return }
        
        self.models = models
                
        self.scrollView.removeAllSubviews()
        
        for model in self.models {
            let view = MessageReadContentView()
            view.configure(with: model)
            self.scrollView.addSubview(view)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.expandToSuperviewSize()
        
        self.scrollView.expandToSuperviewSize()
        
        var xOffset: CGFloat = 0
        var count: Int = 0
        self.scrollView.subviews.forEach { view in
            if let personView = view as? MessageReadContentView {
                personView.frame = CGRect(x: xOffset,
                                          y: 0,
                                          width: 30,
                                          height: self.height)
                xOffset += view.width + Theme.ContentOffset.xtraLong.value
                count += 1
            }
        }
        
        xOffset -= Theme.ContentOffset.xtraLong.value
        
        self.scrollView.contentSize = CGSize(width: xOffset, height: self.height)
    }
}
