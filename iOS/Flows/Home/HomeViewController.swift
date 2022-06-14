//
//  HomeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Transitions

class HomeViewController: ViewController {
    
    enum State {
        case initial
        case tabs
        case shortcuts
    }
        
    private let topGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor,
                                                                 ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                          startPoint: .topCenter,
                                                          endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                             startPoint: .bottomCenter,
                                                             endPoint: .topCenter)
    
    lazy var conversationsVC = ConversationsViewController()
    lazy var membersVC = MembersViewController()
    lazy var noticesVC = NoticesViewController()
    
    private let shortcutButton = ShortcutButton()
    
    private var currentVC: UIViewController?
    
    let tabView = TabView()
    
    @Published var state: State = .initial
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.tabView)
        self.view.addSubview(self.shortcutButton)
        
        self.shortcutButton.didSelect { [unowned self] in
            self.state = self.state == .shortcuts ? .tabs : .shortcuts
        }
        
        self.tabView.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handleTab(state: state)
        }.store(in: &self.cancellables)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
        }.store(in: &self.cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.state = .tabs
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = 80
        self.topGradientView.pin(.top)
        
        self.shortcutButton.squaredSize = 60
        self.shortcutButton.pin(.left, offset: .screenPadding)
        self.shortcutButton.pinToSafeAreaBottom()
        
        self.tabView.height = 60
        self.tabView.width = self.view.halfWidth
        self.tabView.pinToSafeAreaBottom()
        
        switch self.state {
        case .initial:
            
            //self.shortcutButton.transform = CGAffineTransform.init(scaleX: 0.01, y: 0.01)
           // self.shortcutButton.alpha = 0
            
            self.tabView.match(.left, to: .right, of: self.view)
        case .tabs:
            //self.shortcutButton.transform = .identity
            //self.shortcutButton.alpha = 1.0
            self.tabView.pin(.right)

        case .shortcuts:
            self.tabView.match(.left, to: .right, of: self.view)
        }

        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = self.view.height - self.tabView.top
        self.bottomGradientView.pin(.bottom)
        
        if let vc = self.currentVC {
            vc.view.expandToSuperviewSize()
        }
    }
    
    private var stateTask: Task<Void, Never>?

    private func handle(state: State) {
        self.stateTask?.cancel()
        
        self.stateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitSpringAnimation(with: .slow) {
                self.view.layoutNow()
            }
        }
    }
    
    private var loadTask: Task<Void, Never>?
    
    private func handleTab(state: TabView.State) {
        
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            if let vc = self.currentVC {
                await UIView.awaitAnimation(with: .fast) {
                    vc.view.alpha = 0.0
                }
            }
            
            guard !Task.isCancelled else { return }
            
            self.children.forEach { child in
                child.removeFromParent()
            }
            
            switch state {
            case .members:
                self.currentVC = self.membersVC
            case .conversations:
                self.currentVC = self.conversationsVC
            case .notices:
                break
            }
            
            guard let vc = self.currentVC else { return }
            
            vc.view.alpha = 0
            self.addChild(vc)
            self.view.insertSubview(vc.view, belowSubview: self.topGradientView)
            self.view.layoutNow()
            
            await UIView.awaitAnimation(with: .fast, animations: {
                vc.view.alpha = 1.0
            })
        }
    }
}

extension HomeViewController: TransitionableViewController {

    var presentationType: TransitionType {
        return .fadeOutIn
    }

    var dismissalType: TransitionType {
        return self.presentationType
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        return fromVCDismissalType
    }
}
