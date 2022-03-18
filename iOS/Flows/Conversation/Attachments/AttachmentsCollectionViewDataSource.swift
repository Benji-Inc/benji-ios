//
//  AttachementsCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentsCollectionViewDataSource: CollectionViewDataSource<AttachmentsCollectionViewDataSource.SectionType,
                                            AttachmentsCollectionViewDataSource.ItemType> {
    
    enum OptionType: String {
        case capture
        case audio
        case video
        case giphy
        
        var image: UIImage? {
            switch self {
            case .capture:
                return UIImage(systemName: "camera")
            case .audio:
                return UIImage(systemName: "mic")
            case .video:
                return UIImage(systemName: "video")
            case .giphy:
                return UIImage(systemName: "photo")
            }
        }
        
        var title: String {
            switch self {
            case .capture:
                return ""
            case .audio:
                return "Record an Audio Clip"
            case .video:
                return "Record a Video Clip"
            case .giphy:
                return "Choose a GIF"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .capture:
                return true
            default:
                return false 
            }
        }
    }

    enum SectionType: Int, CaseIterable {
        case photoVideo
        case other
    }

    enum ItemType: Hashable {
        case attachment(Attachment)
        case option(OptionType)
    }

    private let config = ManageableCellRegistration<AttachmentCell>().provider
    private let captureConfig = ManageableCellRegistration<CaptureCell>().provider
    private let optionConfig = ManageableCellRegistration<AttachmentOptionCell>().provider
    private let headerConfig = ManageableHeaderRegistration<AttachmentHeaderView>().provider
    
    var didSelectLibrary: CompletionOptional = nil
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .attachment(let attachment):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: attachment)
        case .option(let option):
            switch option {
            case .capture:
                return collectionView.dequeueConfiguredReusableCell(using: self.captureConfig,
                                                                    for: indexPath,
                                                                    item: option)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: self.optionConfig,
                                                                    for: indexPath,
                                                                    item: option)
            }
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String, section: SectionType, indexPath: IndexPath) -> UICollectionReusableView? {
        
        let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
        
        header.didSelectButton = { [unowned self] in
            self.didSelectLibrary?()
        }
        
        return header
    }
}
