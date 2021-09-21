//
//  ConversationSearchBar.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ConversationsSearchBar: UISearchBar {

    enum Scope: Int, CaseIterable {
        case recents
        case dms
        case groups

        var title: Localized {
            switch self {
            case .recents:
                return "Recents"
            case .dms:
                return "DMs"
            case .groups:
                return "Groups"
            }
        }
    }

    var currentScope: Scope {
        return Scope.init(rawValue: self.selectedScopeButtonIndex) ?? .recents
    }
    
    init() {
        super.init(frame: .zero)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {

        self.searchBarStyle = .minimal
        self.isTranslucent = true
        self.backgroundColor = .clear
        self.backgroundImage = UIImage()
        self.scopeBarBackgroundImage = UIImage()

        let titles = Scope.allCases.map { scope in
            return localized(scope.title)
        }
        
        self.scopeButtonTitles = titles
        self.setShowsScope(true, animated: false)
    }
}
