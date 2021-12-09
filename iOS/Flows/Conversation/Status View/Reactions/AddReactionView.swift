//
//  AddReactionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class AddReactionView: UICollectionReusableView {

    let imageView = DisplayableImageView()
    let button = Button()
    var taskPool = TaskPool()
    var message: Message?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {
        self.addSubview(self.imageView)
        self.imageView.displayable = UIImage(named: "add_reaction")
        self.imageView.imageView.tintColor = Color.white.color.withAlphaComponent(0.8)
        self.imageView.imageView.contentMode = .scaleAspectFit

        self.addSubview(self.button)
        self.button.showsMenuAsPrimaryAction = true
        self.button.menu = self.configureMenu()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.expandToSuperviewSize()

        self.imageView.squaredSize = 16
        self.imageView.centerOnXAndY()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        Task {
            await self.taskPool.cancelAndRemoveAll()
        }
    }

    private func configureMenu() -> UIMenu {
        let children: [UIAction] = ReactionType.allCases.filter({ type in
            return type != .read
        }).compactMap { type in
            return UIAction.init(title: type.emoji,
                                 subtitle: nil,
                                 image: nil,
                                 identifier: nil,
                                 discoverabilityTitle: nil,
                                 attributes: []) { [unowned self] _ in

                self.addReaction(type)
            }
        }

        return UIMenu(title: "Add Reaction",
                      image: UIImage(systemName: "face.smiling"),
                      identifier: nil,
                      options: [],
                      children: children)
    }

    private func addReaction(_ reaction: ReactionType) {
        guard let message = self.message, let cid = message.cid else { return }

        Task {
            let controller = ChatClient.shared.messageController(cid: cid, messageId: message.id)
            do {
                try await controller.addReaction(with: reaction)
            } catch {
                logDebug(error)
            }
        }.add(to: self.taskPool)
    }
}
