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
    
    private let headerView = HomeHeaderView()
    
    private let topGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor,
                                                                 ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                          startPoint: .topCenter,
                                                          endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                             startPoint: .bottomCenter,
                                                             endPoint: .topCenter)
    
    lazy var conversationsVC = ConversationsViewController()
    lazy var connectionsVC = ConnectionsViewController()
    
    let tabView = TabView()
    
    // Header
    // Tabs
    // Shortcuts
    // Notices
    // Users VC
    // Conversations VC
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.headerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.headerView.height = 46
        self.headerView.expandToSuperviewWidth()
        self.headerView.pinToSafeArea(.top, offset: .noOffset)
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = self.headerView.bottom
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
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
