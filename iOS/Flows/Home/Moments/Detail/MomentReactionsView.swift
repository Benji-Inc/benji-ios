//
//  MomentReactionsView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MomentReactionsView: BaseView {
    
    private let button = ThemeButton()
    let reactionsView = ReactionsView()
    private let badgeView = BadgeCounterView()
    
    private var controller: ConversationController?
    private var subscriptions = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.reactionsView)
        self.reactionsView.expressionVideoView.shouldPlay = true 
        
        self.addSubview(self.button)
        let pointSize: CGFloat = 26
        
        self.button.set(style: .image(symbol: .faceSmiling,
                                      palletteColors: [.white],
                                      pointSize: pointSize,
                                      backgroundColor: .clear))
        
        self.button.isHidden = true
        
        self.addSubview(self.badgeView)
        self.badgeView.minToShow = 1
        
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reactionsView.expandToSuperviewSize()
        self.button.expandToSuperviewSize()
        
        self.badgeView.center = CGPoint(x: self.width - 2,
                                        y: self.height - 2)
    }
    
    func configure(with moment: Moment) {
        
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        let expressions = self.controller?.conversation?.expressions ?? []
        
        self.badgeView.set(value: expressions.count)
        
        if !expressions.isEmpty {
            self.reactionsView.set(expressions: expressions)
            self.reactionsView.isHidden = false
            self.button.isHidden = true
        } else {
            self.button.isHidden = false
            self.reactionsView.isHidden = true
        }
        
        self.controller?.channelChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            let expressions = self.controller?.conversation?.expressions ?? []
            self.badgeView.set(value: expressions.count)
            
            if !expressions.isEmpty {
                self.reactionsView.set(expressions: expressions)
                self.reactionsView.isHidden = false
                self.button.isHidden = true
            } else {
                self.button.isHidden = false
                self.reactionsView.isHidden = true
            }
            
        }).store(in: &self.subscriptions)
    }
}

class ReactionsView: BaseView {
    
    let emotionGradientView = EmotionGradientView()
    let expressionVideoView = ReactionsVideoView()
    var cornerRadiusRatio: CGFloat = 0.25
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.insertSubview(self.emotionGradientView, at: 0)

        self.addSubview(self.expressionVideoView)
        self.expressionVideoView.layer.masksToBounds = true
        self.expressionVideoView.clipsToBounds = true

        self.set(emotionCounts: [:])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.height * self.cornerRadiusRatio

        self.emotionGradientView.expandToSuperviewSize()
        self.emotionGradientView.layer.cornerRadius = self.layer.cornerRadius

        self.expressionVideoView.expandToSuperviewSize()
        self.expressionVideoView.layer.cornerRadius = self.layer.cornerRadius
    }
    
    func getSize(forHeight height: CGFloat) -> CGSize {
        return CGSize(width: height, height: height)
    }

    func setSize(forHeight height: CGFloat) {
        self.size = self.getSize(forHeight: height)
    }

    // MARK: - Open setters
    
    /// The currently running task that is loading the expression.
    private var loadTask: Task<Void, Never>?
    
    func set(expressions: [ExpressionInfo], defaultColors: [ThemeColor] = [.B0, .B6]) {
        
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            var all: [Expression] = []
            
            await expressions.asyncForEach { info in
                guard !Task.isCancelled else { return }
                
                if let expression = try? await Expression.getObject(with: info.expressionId) {
                    all.append(expression)
                }
            }

            self.expressionVideoView.expressions = all
        }
    }
    
    func set(emotionCounts: [Emotion: Int], defaultColors: [ThemeColor] = [.B0, .B6]) {
        self.emotionGradientView.defaultColors = defaultColors
        let last = self.emotionGradientView.set(emotionCounts: emotionCounts).last
                
        self.layer.borderWidth = 2
        self.layer.borderColor = last?.withAlphaComponent(0.9).cgColor
        self.layer.masksToBounds = false
        
        self.setNeedsLayout()
    }
}

class ReactionsVideoView: VideoView {

    var expressions: [Expression] = [] {
        didSet {
            // Only update the video if this is a new set of expressions.
            guard self.expressions != oldValue else { return }

            self.reset()
            self.updatePlayer()
        }
    }
    
    /// The currently running task that loads the video url.
    private var loadTask: Task<Void, Never>?
    
    private func updatePlayer() {
        self.loadTask?.cancel()

        self.loadTask = Task { [weak self] in
            
            var allURLs: [URL] = []
            
            await self?.expressions.asyncForEach { expression in
                guard let videoURL = try? await expression.file?.retrieveCachedPathURL() else { return }
                guard !Task.isCancelled else { return }

                allURLs.append(videoURL)
            }
            
            self?.updatePlayer(with: allURLs)
        }
    }
}
