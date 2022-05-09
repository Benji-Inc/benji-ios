//
//  AttachmentsCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentsCollectionViewDataSource: CollectionViewDataSource<AttachmentsCollectionViewDataSource.SectionType,
                                            AttachmentsCollectionViewDataSource.ItemType> {
    
    enum OptionType: String, OptionDisplayable {
        case capture
        case audio
        case giphy
        
        var image: UIImage? {
            switch self {
            case .capture:
                return UIImage(systemName: "camera")
            case .audio:
                return UIImage(systemName: "mic")
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
            case .giphy:
                return "Choose a GIF"
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
    private let headerConfig = ManageableHeaderRegistration<SectionHeaderView>().provider
    
    var didSelectLibrary: CompletionOptional = nil
    var didSelectOption: ((OptionType) -> Void)? = nil
    
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
                let cell = collectionView.dequeueConfiguredReusableCell(using: self.captureConfig,
                                                                        for: indexPath,
                                                                        item: option)
                cell.contentView.didSelect { [unowned self] in
                    self.didSelectOption?(option)
                }
                return cell
            default:
                let lastIndex = self.snapshot().numberOfItems(inSection: section) - 1
                let shouldHideLine = lastIndex == indexPath.row
                let cell = collectionView.dequeueConfiguredReusableCell(using: self.optionConfig,
                                                                        for: indexPath,
                                                                        item: option)
                cell.lineView.isHidden = shouldHideLine
                cell.contentView.didSelect { [unowned self] in
                    self.didSelectOption?(option)
                }
                return cell 
            }
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .photoVideo:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.leftLabel.setText("Photo & Video")
            header.rightLabel.setText("View Library")
            header.lineView.isHidden = true 
            header.didSelectButton = { [unowned self] in
                self.didSelectLibrary?()
            }
            
            return header
        case .other:
            return nil
        }
    }
}
