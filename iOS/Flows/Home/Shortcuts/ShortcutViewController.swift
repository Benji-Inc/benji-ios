//
//  ShortcutViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutViewController: ViewController, HomeStateHandler {
    
    private let blurView = DarkBlurView()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.addSubview(self.blurView)
        self.blurView.showBlur(false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
    }
    
    private var stateTask: Task<Void, Never>?

    func handleHome(state: HomeState) {
        self.stateTask?.cancel()
        
        self.stateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitAnimation(with: .fast, animations: {
                switch state {
                case .initial, .tabs:
                    self.blurView.showBlur(false)
                case .shortcuts:
                    self.blurView.showBlur(true)
                }
            })
        }
    }
}
