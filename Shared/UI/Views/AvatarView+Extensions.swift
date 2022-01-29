//
//  AvatarView+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension AvatarView: AvatarContextDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let avatar = self.avatar else { return nil }

        return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
            return AvatarProfileViewController(with: avatar)
        } actionProvider: { (suggestions) -> UIMenu? in
            return self.getMenu(for: avatar)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {

    }
}
