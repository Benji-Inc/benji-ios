//
//  MomentCell+Preview.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension MomentCell: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil) { [unowned self] () -> UIViewController? in
            guard let moment = self.moment else { return nil }
            return MomentPreviewViewController(with: moment)
        } actionProvider: { [unowned self] (suggestions) -> UIMenu? in
            return self.makeContextMenu()
        }
    }
    
    private func makeContextMenu() -> UIMenu? {
        guard let moment = self.moment else { return nil }
        
        var children: [UIMenuElement] = []
        
        if moment.isAvailable {
            let view = UIAction(title: "View",
                                image: ImageSymbol.personCircle.image) { [unowned self] _ in
                self.delegate?.moment(self, didSelect: moment)
            }
            children.append(view)
        } else {
            let view = UIAction(title: "Record",
                                image: ImageSymbol.recordingTape.image) { [unowned self] _ in
                self.delegate?.momentCellDidSelectRecord(self)
            }
            children.append(view)
        }
        
        return UIMenu(title: "", children: children)
    }
}
