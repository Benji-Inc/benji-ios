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
    let avatarView = CircleAvatarView()
    var cancellables = Set<AnyCancellable>()
    
    enum State {
        case empty
        case contact
        case connection
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
        self.addSubview(self.avatarView)
        self.clipsToBounds = false
        
        self.$uiState.mainSink { [unowned self] state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
        
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.expandToSuperviewSize()
        self.emptyView.expandToSuperviewSize()
    }
    
    private func handle(state: State) {
        switch state {
        case .empty:
            // update border to be dashed lines
            break
        case .contact:
            // update border to reflect focus and show initials
            break
        case .connection:
            // update border to reflect focus and show image
            break
        }
    }
}
