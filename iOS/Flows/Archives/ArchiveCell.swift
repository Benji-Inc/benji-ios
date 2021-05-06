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

    var currentItem: Post?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.cornerRadius = 5 
        self.imageView.clipsToBounds = true 

        self.contentView.addSubview(self.gradientView)

        self.contentView.addSubview(self.label)
        self.label.setTextColor(.background4)
    }

    func configure(with item: Post) {

        let file = item.preview ?? item.file

        if item.author == User.current() {
            self.imageView.displayable = file
            self.label.setText(item.createdAt?.getDistanceAgoString() ?? String())
            self.layoutNow()
        } else {
            switch RitualManager.shared.state {
            case .feedAvailable:
                self.imageView.displayable = file
                self.label.setText(item.createdAt?.getDistanceAgoString() ?? String())
                self.layoutNow()
            default:
                if let trigger = item.triggerDate,
                   let currentTrigger = RitualManager.shared.currentTriggerDate,
                   currentTrigger.isSameDay(as: trigger) {
                    self.imageView.loadingIndicator.stopAnimating()
                    self.imageView.symbolImageView.image = UIImage(systemName: "lock.fill")
                    self.imageView.layoutNow()
                } else {
                    self.imageView.displayable = file
                    self.label.setText(item.createdAt?.getDistanceAgoString() ?? String())
                    self.layoutNow()
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.contentView.halfHeight
        self.gradientView.pin(.bottom)

        self.label.setSize(withWidth: self.width)
        self.label.pin(.left, padding: 6)
        self.label.pin(.bottom, padding: 6)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.displayable = nil
        self.label.text = nil
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
