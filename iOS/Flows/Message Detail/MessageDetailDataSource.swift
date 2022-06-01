//
//  MessageDetailDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailDataSource: CollectionViewDataSource<MessageDetailDataSource.SectionType, MessageDetailDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case options
        case reads
        case metadata
    }
    
    enum OptionType: Int, OptionDisplayable {
        
        case viewThread
        case edit
        case pin
        case unpin
        case more
        case quote
        
        var image: UIImage? {
            switch self {
            case .viewThread:
                return ImageSymbol.arrowTurnUpLeft.image
            case .edit:
                return ImageSymbol.pencil.image
            case .pin:
                return ImageSymbol.bookmark.image
            case .unpin:
                return ImageSymbol.bookmarkSlash.image
            case .more:
                return ImageSymbol.ellipsis.image
            case .quote:
                return ImageSymbol.quoteOpening.image
            }
        }
        
        var title: String {
            switch self {
            case .viewThread:
                return "View Thread"
            case .edit:
                return "Edit"
            case .pin:
                return "Pin"
            case .unpin:
                return "Unpin"
            case .more:
                return "More"
            case .quote:
                return "Quote"
            }
        }
        
        var color: ThemeColor {
            switch self {
            default:
                return .white
            }
        }
    }

    enum ItemType: Hashable {
        case more(MoreOptionModel)
        case option(OptionType)
        case read(ReadViewModel)
        case metadata(MetadataModel)
    }
    
    private let topOptionConfig = ManageableCellRegistration<MessageTopOptionCell>().provider
    private let readConfig = ManageableCellRegistration<MessageReadCell>().provider
    private let headerConfig = ManageableHeaderRegistration<SectionHeaderView>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
    private let metadatConfig = ManageableCellRegistration<MessageMetadataCell>().provider
    private let moreConfige = ManageableCellRegistration<MessageMoreCell>().provider
    
    var didTapEdit: CompletionOptional = nil
    var didTapDelete: CompletionOptional = nil

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .option(let option):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.topOptionConfig,
                                                                    for: indexPath,
                                                                    item: option)
            return cell
        case .read(let read):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.readConfig,
                                                                    for: indexPath,
                                                                    item: read)
            return cell
        case .metadata(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.metadatConfig,
                                                                    for: indexPath,
                                                                    item: model)
            return cell
        case .more(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.moreConfige,
                                                                    for: indexPath,
                                                                    item: model)
            cell.didTapEdit = { [unowned self] in
                self.didTapEdit?()
            }
            
            cell.didTapDelete = { [unowned self] in
                self.didTapDelete?()
            }
            
            return cell
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)

            switch section {
            case .options:
                break
            case .reads:
                header.leftLabel.setText("Read by")
            case .metadata:
                header.leftLabel.setText("Metadata")
            }
            
            header.rightLabel.isHidden = true
            header.button.isHidden = true
            header.lineView.isHidden = true 
            return header
        default:
            return nil
        }
    }
}
