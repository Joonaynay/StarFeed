//
//  BackButton.swift
//  StarFeed
//
//  Created by Forrest Buhler on 10/13/21.
//

import UIKit
import TinyConstraints

class BackButton: UIButton {
    
    let vc: UIViewController

    init(vc: UIViewController) {
        self.vc = vc
        super.init(frame: .zero)
        setImage(UIImage(systemName: "chevron.left"), for: .normal)
        vc.view.addSubview(self)
        contentVerticalAlignment = .fill
        contentHorizontalAlignment = .fill
        imageEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        height(45)
        width(45)
        leadingToSuperview(offset: 10)
        topToSuperview(offset: 10, usingSafeArea: true)
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        
    }
    
    @objc private func didTap() {
        vc.navigationController?.popViewController(animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
