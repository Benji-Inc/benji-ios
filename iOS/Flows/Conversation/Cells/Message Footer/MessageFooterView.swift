//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

private typealias MessageDetailContent = BaseView & MessageConfigureable

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 86
    static let collapsedHeight: CGFloat = 30 

    let replySummary = MessageSummaryView()
    let experessionSummary = ExpressionSummaryView()
    let readSummary = ReadSummaryView()
    
    var didTapViewReplies: CompletionOptional = nil
    
    let detailView  = MessageFooterDetailContainerView()
    let statusLabel = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    
    let selectedDetailContainerView = BaseView()
        
    private var message: Messageable?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.statusLabel)
        self.statusLabel.textAlignment = .right
        
        self.addSubview(self.detailView)
        self.detailView.alpha = 0
        
        self.addSubview(self.selectedDetailContainerView)
        
        self.detailView.$state.mainSink { [unowned self] state in
            switch state {
            case .replies:
                self.handleUpdated(content: self.replySummary)
            case .expressions:
                self.handleUpdated(content: self.experessionSummary)
            case .reads:
                self.handleUpdated(content: self.readSummary)
            }
        }.store(in: &self.cancellables)
        
        self.replySummary.replyView.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
        
        self.detailView.didTapViewReplies = { [unowned self] in
            self.didTapViewReplies?()
        }
    }
    
    func configure(for message: Messageable) {
        self.message = message
        self.detailView.configure(for: message)
        self.updateStatus(for: message)
        // Start with replies
        if message.parentMessageId.exists {
            self.detailView.expressionsView.selectionState = .selected
        } else {
            self.detailView.repliesView.selectionState = .selected
        }
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.detailView.expandToSuperviewWidth()
        self.detailView.pin(.top)
        self.detailView.pin(.left)
        
        self.selectedDetailContainerView.expandToSuperviewWidth()
        self.selectedDetailContainerView.height = self.height - self.detailView.height - Theme.ContentOffset.standard.value
        self.selectedDetailContainerView.match(.top, to: .bottom, of: self.detailView, offset: .standard)
        
        if let content = self.selectedDetailContainerView.subviews.first(where: { view in
            return view is MessageConfigureable
        }) {
            content.expandToSuperviewSize()
        }
        
        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.top, offset: .short)
        self.statusLabel.pin(.right)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only handle touches on the reply and read views.
        let replyPoint = self.convert(point, to: self.selectedDetailContainerView)
        let readPoint = self.convert(point, to: self.detailView)

        return self.selectedDetailContainerView.point(inside: replyPoint, with: event)
        || self.detailView.point(inside: readPoint, with: event)
    }

    private func getString(for deliveryStatus: DeliveryStatus) -> String {
        switch deliveryStatus {
        case .sending:
            return "sending..."
        case .sent,.reading, .read:
            return "sent"
        case .error:
            return "failed to send"
        }
    }
    
    private func updateStatus(for message: Messageable) {
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            switch message.deliveryStatus {
            case .sending, .error:
                self.statusLabel.text = self.getString(for: message.deliveryStatus)
                self.statusLabel.alpha = 1
                self.detailView.alpha = 0
                if message.deliveryStatus == .sending {
                    self.statusLabel.textColor =  ThemeColor.whiteWithAlpha.color
                    self.statusLabel.font = FontType.small.font
                } else {
                    self.statusLabel.textColor = ThemeColor.red.color
                    self.statusLabel.font = FontType.smallBold.font
                }
            case .sent, .reading, .read:
                self.statusLabel.alpha = 0
                self.detailView.alpha = 1.0
            }
            self.layoutNow()
        }
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    private func handleUpdated(content: MessageDetailContent) {
        
        self.loadTask?.cancel()
                
        self.loadTask = Task { [weak self] in
            guard let `self` = self, let msg = self.message else { return }
            
            await UIView.awaitAnimation(with: .standard, animations: {
                self.selectedDetailContainerView.subviews.forEach { view in
                    view.alpha = 0
                }
            })
            
            self.selectedDetailContainerView.removeAllSubviews()
            
            content.alpha = 0.0
            self.selectedDetailContainerView.addSubview(content)
            content.configure(for: msg)
            content.expandToSuperviewSize()
            self.layoutNow()
            
            guard !Task.isCancelled else {
                content.alpha = 1.0
                return
            }
            
            await UIView.awaitAnimation(with: .standard, animations: {
                self.selectedDetailContainerView.subviews.forEach { view in
                    view.alpha = 1
                }
            })
        }
    }
}
