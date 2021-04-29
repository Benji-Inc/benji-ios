//
//  CaptionTextView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CaptionTextView: TextView {

    lazy var countView = CharacterCountView()

    override func initializeViews() {
        super.initializeViews()

        self.addSubview(self.countView)
        self.countView.isHidden = true

        self.maxLength = 140

        self.layer.borderWidth = 2
        self.layer.cornerRadius = 5
        self.layer.borderColor = Color.background4.color.cgColor
        self.clipsToBounds = true

        self.isScrollEnabled = true
        self.keyboardType = .twitter
        self.isEditable = true
        self.enablesReturnKeyAutomatically = true
        self.autocapitalizationType = .sentences
        
        self.textContainerInset.left = 10
        self.textContainerInset.right = 10
        self.textContainerInset.top = Theme.contentOffset.half
        self.textContainerInset.bottom = Theme.contentOffset.half

        self.backgroundColor = Color.background4.color.withAlphaComponent(0.25)

        self.set(placeholder: "Add caption")

        self.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))

    }

    override func textDidChange() {
        super.textDidChange()
        
        self.countView.udpate(with: self.text.count, max: self.maxLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }

    @objc func tapDone(sender: Any) {
        self.endEditing(true)
    }

    func addDoneButton(title: String, target: Any, selector: Selector) {

        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButton = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)
        toolBar.setItems([flexible, barButton], animated: false)
        self.inputAccessoryView = toolBar
    }
}
