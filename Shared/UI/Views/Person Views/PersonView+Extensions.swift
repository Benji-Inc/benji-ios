//
//  PersonView+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension PersonView: PersonContextDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let person = self.person else { return nil }

        return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
            return PersonPreviewViewController(with: person)
        } actionProvider: { (suggestions) -> UIMenu? in
            return self.getMenu(for: person)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {

    }
}
