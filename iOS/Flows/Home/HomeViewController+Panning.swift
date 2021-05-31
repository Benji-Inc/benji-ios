//
//  HomeViewController+Panning.swift
//  Ours
//
//  Created by Benji Dodgson on 5/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension HomeViewController: UIGestureRecognizerDelegate {

    func handle(_ pan: UIPanGestureRecognizer) {
        guard let view = pan.view, !self.isMenuPresenting else {return}

        let translation = pan.translation(in: view.superview)

        switch pan.state {
        case .possible:
            self.isPanning = false
        case .began:
            self.isPanning = false
            self.topOffset = self.minTop
        case .changed:
            self.isPanning = translation.y > 0
            let newTop = self.minTop + translation.y
            self.topOffset = clamp(newTop, self.minTop, self.view.height)
            self.createVC.view.top = self.topOffset!

            let noticesTop = -translation.y
            self.noticesTopOffset = clamp(noticesTop, -NoticesCollectionViewController.height, 0)
            
        case .ended, .cancelled, .failed:
            self.isPanning = false
            let diff = (self.view.height - self.minTop) - self.topOffset!
            let progress = diff / (self.view.height - self.minTop)
            self.topOffset = progress < 0.65 ? self.minBottom : self.minTop
            self.noticesTopOffset = progress < 0.65 ? -NoticesCollectionViewController.height : 0

            self.animate(offset: self.topOffset!, progress: progress)
        @unknown default:
            break
        }

        self.view.layoutNow()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let _ = gestureRecognizer as? UIPanGestureRecognizer, self.isMenuPresenting {
            return false
        } else if let _ = gestureRecognizer as? UIScreenEdgePanGestureRecognizer, self.isPanning {
            return false
        }

        return true
    }
}
