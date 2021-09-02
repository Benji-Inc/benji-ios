//
//  AttachementInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import Combine

protocol AttachmentViewControllerDelegate: AnyObject {
    func attachementView(_ controller: AttachmentViewController, didSelect attachment: Attachment)
}

class AttachmentViewController: CollectionViewController<AttachmentCollectionViewManager.SectionType, AttachmentCollectionViewManager> {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))

    unowned let delegate: AttachmentViewControllerDelegate

    init(with delegate: AttachmentViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func getCollectionView() -> CollectionView {
        return AttachmentCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.didSelectPhotoOption = {
            NotificationCenter.default.post(name: .didTapPhotoCamera, object: nil)
        }

        self.collectionViewManager.didSelectLibraryOption = {
            NotificationCenter.default.post(name: .didTapPhotoLibrary, object: UUID().uuidString)
        }

        self.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let attachment = cellItem?.item as? Attachment else { return }
            self.delegate.attachementView(self, didSelect: attachment)
        }.store(in: &self.cancellables)

        if let attachmentCollectionView = self.collectionViewManager.collectionView as? AttachmentCollectionView {
            attachmentCollectionView.didTapAuthorize = { [unowned self] in
                Task {
                    await self.handleAttachmentAuthorized()
                }
            }
        }
    }

    private func handleAttachmentAuthorized() async {
        do {
            try await AttachmentsManager.shared.requestAttachements()
            await self.collectionViewManager.loadSnapshot()
        } catch {
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            do {
                if AttachmentsManager.shared.isAuthorized {
                    try await AttachmentsManager.shared.requestAttachements()
                    await self.collectionViewManager.loadSnapshot()
                }
            } catch {
                logDebug(error)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.collectionViewManager.collectionView.expandToSuperviewWidth()
        self.collectionViewManager.collectionView.pin(.top, padding: 10)
        self.collectionViewManager.collectionView.height = self.view.height - self.view.safeAreaInsets.bottom - 10
    }
}

extension Notification.Name {
    static let didTapPhotoCamera = Notification.Name("didTapPhotoCamera")
    static let didTapPhotoLibrary = Notification.Name("didTapPhotoLibrary")
}
