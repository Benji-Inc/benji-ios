//
//  ArchiveCell.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Post

    private let gradientView = ArchiveGradientView()
    private let imageView = DisplayableImageView()
    private let label = Label(font: .smallBold)
    private let playImageView = UIImageView(image: UIImage(systemName: "play")!)

    var currentItem: Post?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.cornerRadius = 5 
        self.imageView.clipsToBounds = true

        self.contentView.addSubview(self.playImageView)
        self.playImageView.alpha = 0
        self.playImageView.tintColor = Color.white.color

        self.contentView.addSubview(self.gradientView)

        self.contentView.addSubview(self.label)
        self.label.setTextColor(.background4)
    }

    func configure(with item: Post) {

        self.reset()

        let file = item.preview ?? item.file

        if item.isLocked {
            self.imageView.animationView.stop()
            self.imageView.symbolImageView.image = UIImage(systemName: "lock.fill")
            self.imageView.layoutNow()
        } else {
            self.imageView.displayable = file
            self.playImageView.alpha = item.mediaType == .video ? 1.0 : 0.0
        }

        self.label.setText(item.triggerDate?.getDistanceAgoString() ?? String())
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()

        self.playImageView.squaredSize = 20
        self.playImageView.centerOnXAndY()

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.contentView.halfHeight
        self.gradientView.pin(.bottom)

        self.label.setSize(withWidth: self.width)
        self.label.pin(.left, padding: 6)
        self.label.pin(.bottom, padding: 6)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.reset()
    }

    override func reset() {
        self.imageView.symbolImageView.image = UIImage(systemName: "exclamationmark.triangle")
        self.imageView.displayable = nil
        self.label.text = nil
        self.playImageView.alpha = 0
    }
}

class ArchiveGradientView: GradientView {

    init() {
        let colors: [CGColor] = [Color.background1.color.withAlphaComponent(0.6).cgColor,
                                 Color.background1.color.withAlphaComponent(0).cgColor].reversed()

        super.init(with: colors, startPoint: .topCenter, endPoint: .bottomCenter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
