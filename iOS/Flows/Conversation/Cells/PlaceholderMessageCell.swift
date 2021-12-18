//
//  PlaceholderMessageCell.swift
//  Jibber
//
//  Created by Martin Young on 12/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PlaceholderMessageCell: UICollectionViewCell {

    let dropZoneView = MessageDropZoneView()

    private var animationTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.dropZoneView)
        self.dropZoneView.setState(.newMessage, messageColor: .white)
        self.dropZoneView.alpha = 0

        self.animationTask = Task {
            await self.animateInDropZone()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.dropZoneView.expandToSuperviewWidth()
        self.dropZoneView.height = MessageContentView.bubbleHeight
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.dropZoneView.alpha = 0

        self.animationTask?.cancel()
        self.animationTask = Task {
            await self.animateInDropZone()
        }
    }

    @MainActor
    private func animateInDropZone() async {
        await Task.sleep(seconds: Theme.animationDurationStandard)

        guard !Task.isCancelled else { return }

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.dropZoneView.alpha = 1
        }
    }
}
