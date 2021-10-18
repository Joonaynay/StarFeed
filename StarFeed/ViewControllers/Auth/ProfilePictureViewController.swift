//
//  ProfilePictureViewController.swift
//  StarFeed
//
//  Created by Wendy Buhler on 10/16/21.
//

import UIKit

class ProfilePictureViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    private let storage = StorageModel.shared
    private let auth = AuthModel.shared
    
    private var image: UIImage?
    
    let profileLabel: UILabel = {
        
        let label = UILabel()
        label.text = "Choose a profile picture"
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center
        return label
        
    }()
    
    let profileImageButton: UIButton = {
       
        let button = UIButton()
        button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
        
    }()
    
    let skipButton = Button(text: "Skip", color: .clear)
    
    let doneButton = Button(text: "Done", color: UIColor.theme.blueColor)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addConstraints()
        
    }
    
    func setupView() {
        
        view.backgroundColor = .systemBackground
        view.addSubview(profileLabel)
        view.addSubview(profileImageButton)
        view.addSubview(doneButton)
        view.addSubview(skipButton)
        
        profileImageButton.addAction(UIAction() { _ in
            self.presentImagePicker(type: ["public.image"])
        }, for: .touchUpInside)
        
        doneButton.addAction(UIAction() { _ in
            if let image = self.image {
                self.storage.saveImage(path: "Profile Images", file: self.auth.currentUser.id, image: image)
            }
            let home = TabBarController()
            home.modalTransitionStyle = .flipHorizontal
            home.modalPresentationStyle = .fullScreen
            self.present(home, animated: true)
        }, for: .touchUpInside)
    }
    
    func addConstraints() {
        
        profileLabel.edgesToSuperview(excluding: .bottom, insets: UIEdgeInsets(top: 20, left: 15, bottom: 0, right: 15), usingSafeArea: true)
        profileLabel.centerXToSuperview()
                
        profileImageButton.centerYToSuperview(offset: -20)
        profileImageButton.horizontalToSuperview(insets: UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50))
        profileImageButton.heightToWidth(of: view, offset: -100)
        
        doneButton.bottomToTop(of: skipButton)
        doneButton.horizontalToSuperview(insets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
        doneButton.height(50)
        
        skipButton.bottomToSuperview(offset: -10)
        skipButton.horizontalToSuperview(insets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
        skipButton.height(50)
    }
    
    func presentImagePicker(type: [String]) {
        
        let picker = ImagePicker(mediaTypes: type, allowsEditing: type == ["public.image"])
        picker.delegate = self
        present(picker, animated: true)
    }
                        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let image = info[.editedImage] as? UIImage {
            self.image = image
            self.profileImageButton.setImage(image, for: .normal)
        }
    }
}
