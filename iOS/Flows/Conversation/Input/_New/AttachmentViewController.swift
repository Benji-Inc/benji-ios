//
//  AttachementInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

protocol AttachmentViewControllerDelegate: AnyObject {
    func attachmentView(_ controller: AttachmentViewController, didSelect attachment: Attachment)
}

class AttachmentViewController: ViewController {

    private lazy var dataSource = AttachmentCollectionViewDataSource(collectionView: self.collectionView)
    private var collectionView = AttachmentCollectionView()

    let blurView = BlurView()

    unowned let delegate: AttachmentViewControllerDelegate

    init(with delegate: AttachmentViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.dataSource.didSelectPhotoOption = {
            NotificationCenter.default.post(name: .didTapPhotoCamera, object: nil)
        }

        self.dataSource.didSelectLibraryOption = {
            NotificationCenter.default.post(name: .didTapPhotoLibrary, object: UUID().uuidString)
        }

        // CollectionView setup
        self.collectionView.delegate = self
        self.view.addSubview(self.collectionView)
        self.collectionView.didTapAuthorize = { [unowned self] in
            Task {
                await self.handleAttachmentAuthorized()
            }
        }
    }

    private func handleAttachmentAuthorized() async {
        do {
            try await AttachmentsManager.shared.requestAttachments()
            await self.loadInitialAttachmentData()
        } catch {
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            do {
                if AttachmentsManager.shared.isAuthorized {
                    try await AttachmentsManager.shared.requestAttachments()
                    await self.loadInitialAttachmentData()
                }
            } catch {
                logDebug(error)
            }
        }
    }

    private func loadInitialAttachmentData() async {
        await self.dataSource.appendSections([.photos])
        let attachmentItems = AttachmentsManager.shared.attachments.map { attachment in
            return AttachmentCollectionItem.attachment(attachment: attachment)
        }
        await self.dataSource.appendItems(attachmentItems, toSection: .photos)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.dataSource.deleteSections([.photos])
    }
}

extension AttachmentViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .attachment(let attachment):
            self.delegate.attachmentView(self, didSelect: attachment)
        }
    }
}

extension Notification.Name {
    static let didTapPhotoCamera = Notification.Name("didTapPhotoCamera")
    static let didTapPhotoLibrary = Notification.Name("didTapPhotoLibrary")
}
