//
//  CircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CircleView: BaseView {
    
    let emptyView = EmptyCircleView()
    let initialsView = InitialsCircleView()
    let avatarView = CircleAvatarView()
    var cancellables = Set<AnyCancellable>()
    
    enum State {
        case empty
        case initials
        case user
    }
    
    @Published var uiState: State = .empty
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.avatarView.isHidden = true 
        
        self.addSubview(self.emptyView)
        self.addSubview(self.initialsView)
        self.addSubview(self.avatarView)
        self.clipsToBounds = false
        
        self.$uiState.mainSink { [unowned self] state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
        
        self.clipsToBounds = false
        
        self.uiState = .empty
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.expandToSuperviewSize()
        self.initialsView.expandToSuperviewSize()
        self.emptyView.expandToSuperviewSize()
    }
    
    private func handle(state: State) {
        switch state {
        case .empty:
            self.emptyView.isHidden = false
            self.avatarView.isHidden = true
            self.initialsView.isHidden = true
        case .initials:
            self.emptyView.isHidden = true
            self.avatarView.isHidden = true
            self.initialsView.isHidden = false
        case .user:
            self.emptyView.isHidden = true
            self.avatarView.isHidden = false
            self.initialsView.isHidden = true
        }
    }
}
