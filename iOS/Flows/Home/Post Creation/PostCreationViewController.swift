//
//  PostCreationViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostCreationViewController: ImageCaptureViewController {

    let flipButton = Button()
    let photoLibraryButton = Button()
    let exitButton = Button()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.flipButton)
        self.flipButton.set(style: .icon(image: UIImage(systemName: "")!, color: .white))
        self.flipButton.didSelect { [unowned self] in

        }

        self.view.addSubview(self.flipButton)
        self.photoLibraryButton.set(style: .icon(image: UIImage(systemName: "")!, color: .white))
        self.photoLibraryButton.didSelect { [unowned self] in

        }

        self.view.addSubview(self.flipButton)
        self.exitButton.set(style: .icon(image: UIImage(systemName: "")!, color: .white))
        self.exitButton.didSelect { [unowned self] in

        }

    }


    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.flipButton.alpha = show ? 1.0 : 0.0
            self.photoLibraryButton.alpha = show ? 1.0 : 0.0
            self.exitButton.alpha = show ? 1.0 : 0.0
        }
    }
}
