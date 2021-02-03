//
//  ProfilePhotoViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 2/1/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

enum PhotoContentType: Switchable {

    case photo(PhotoViewController)

    var viewController: UIViewController & Sizeable {
        switch self {
        case .photo(let vc):
            return vc
        }
    }

    var shouldShowBackButton: Bool {
        return false
    }
}

protocol ProfilePhotoViewControllerDelegate: AnyObject {
    func profilePhotoViewControllerDidFinish(_ controller: ProfilePhotoViewController)
}

class ProfilePhotoViewController: SwitchableContentViewController<PhotoContentType> {

    lazy var photoVC = PhotoViewController()

    unowned let delegate: ProfilePhotoViewControllerDelegate

    init(with delegate: ProfilePhotoViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.photoVC.view.set(backgroundColor: .clear)

        self.photoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success:
                self.delegate.profilePhotoViewControllerDidFinish(self)
            case .failure(_):
                break 
            }
        }

        self.photoVC.$currentState
            .removeDuplicates()
            .mainSink { [weak self] (_) in
            guard let `self` = self else { return }
                self.updateNavigationBar(animateBackButton: false)

            }.store(in: &self.cancellables)
    }

    override func getInitialContent() -> PhotoContentType {
        return .photo(self.photoVC)
    }

    override func getTitle() -> Localized {
        switch self.photoVC.currentState {
        case .initial:
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Verify Indentity")
        case .scan:
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Scanning...")
        case .capture:
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Identity Verified")
        case .error:
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Error!")
        case .finish:
            return LocalizedString.empty
        }
    }

    override func getDescription() -> Localized {
        return LocalizedString(id: "",
                               arguments: [],
                               default: "For the safety of yourself and others, we require a front facing photo. This helps ensure everyone is who they say they are. No 🤖's!")
    }
}
