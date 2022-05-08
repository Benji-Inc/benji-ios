//
//  AttachmentsCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum AttachmentOption {
    case attachments([Attachment])
    case capture
    case audio
    case giphy
    case video
    case library
}

class AttachmentsCoordinator: PresentableCoordinator<AttachmentOption> {
    
    lazy var attachmentsVC = AttachmentsViewController()
    
    override init(router: Router, deepLink: DeepLinkable?) {
        super.init(router: router, deepLink: deepLink)
        
        self.attachmentsVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
        
            switch first {
            case .attachment(let attachment):
                self.finishFlow(with: .attachments([attachment]))
            case .option(let option):
                switch option {
                case .capture:
                    self.finishFlow(with: .capture)
                case .audio:
                    self.presentAlert(for: option)
                case .giphy:
                    self.presentAlert(for: option)
                }
            }
            
        }.store(in: &self.cancellables)
        
        self.attachmentsVC.dataSource.didSelectLibrary = { [unowned self] in
            self.finishFlow(with: .library)
        }
    }

    override func toPresentable() -> DismissableVC {
        return self.attachmentsVC
    }
    
    private func presentAlert(for option: AttachmentsCollectionViewDataSource.OptionType) {
        guard option != .capture else { return }
        
        let alertController = UIAlertController(title: option.title,
                                                message: "(Coming Soon)",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Got it", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        })

        alertController.addAction(cancelAction)
        self.attachmentsVC.present(alertController, animated: true, completion: nil)
    }
}
