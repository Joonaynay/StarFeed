//
//  PostView.swift
//  StarFeed
//
//  Created by Wendy Buhler on 10/14/21.
//

import UIKit
import FirebaseFirestore

class PostView: UICollectionViewCell {
    
    let fb = FirebaseModel.shared
    
    weak var vc: UIViewController?
    
    //Post Title
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .label
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 2
        return titleLabel
    }()
    
    //Main Image/Thumbnail
    public let imageViewButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    //Button to move to comments
    private let commentsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Comments", for: .normal)
        button.setTitleColor(UIColor.theme.lineColor, for: .normal)
        button.setTitleColor(UIColor.theme.secondaryText, for: .highlighted)
        return button
    }()
    
    //Like Count Label
    private let likeCount: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    //Button to like
    private let likeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        button.tintColor = .label
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    //Line at bottom of post for separation
    private let line: UIView = {
        let line = UIView()
        line.backgroundColor = .secondarySystemBackground
        return line
    }()
    
    //Has Profile Image and username
    private let profile = ProfileButton(image: nil, username: "")
    
    private let followButton = Button(text: "Follow", color: UIColor.theme.blueColor)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(commentsButton)
        addSubview(titleLabel)
        addSubview(imageViewButton)
        addSubview(likeButton)
        addSubview(followButton)
        addSubview(profile)
        addSubview(likeCount)
        addSubview(line)
        addConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setPost(post: Post) {
        
        let db = Firestore.firestore()
        db.collection("users").document(post.user.id).addSnapshotListener { doc, error in
            if let followers = doc?.get("followers") as? [String] {
                if followers.contains(self.fb.currentUser.id) {
                    self.followButton.label.text = "Unfollow"
                } else {
                    self.followButton.label.text = "Follow"
                }
            }
        }
        
        followButton.addAction(UIAction() { _ in
            self.fb.followUser(followUser: post.user)
        }, for: .touchUpInside)
        
        imageViewButton.setBackgroundImage(post.image, for: .normal)
        imageViewButton.addAction(UIAction() { _ in
            self.vc?.present(VideoPlayer(url: post.movie!), animated: true)
        }, for: .touchUpInside)
        
        profile.usernameLabel.text = post.user.username
        profile.profileImage.image = post.user.profileImage
        
        let result = String(format: "%ld %@", locale: Locale.current, post.likes.count, "")
        likeCount.text = result
        
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .highlighted)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        
        likeButton.addAction(UIAction() { _ in
            
        }, for: .touchUpInside)
        
        titleLabel.text = post.title
        
        self.reloadInputViews()
        
    }
    
    
    private func addConstraints() {
        
        imageViewButton.edgesToSuperview(excluding: .bottom)
        imageViewButton.heightToWidth(of: self, multiplier: 9/16 )
        imageViewButton.widthToSuperview()
        
        titleLabel.horizontalToSuperview(insets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        titleLabel.topToBottom(of: imageViewButton, offset: 5)
        titleLabel.height(60)
        
        likeButton.topToBottom(of: titleLabel, offset: 10)
        likeButton.trailingToSuperview(offset: 10)
        likeButton.height(32)
        likeButton.width(32)
        
        profile.leadingToSuperview(offset: 5)
        profile.topToBottom(of: titleLabel, offset: 10)
        profile.widthToSuperview(multiplier: 0.4)
        
        likeCount.trailingToLeading(of: likeButton, offset: -5)
        likeCount.topToBottom(of: titleLabel, offset: 15)
        
        followButton.topToBottom(of: titleLabel, offset: 5)
        followButton.trailingToLeading(of: likeCount, offset: -10)
        followButton.height(50)
        followButton.width(UIScreen.main.bounds.width / 4)
        
        commentsButton.bottomToTop(of: line, offset: -5)
        commentsButton.leadingToSuperview(offset: 5)
        
        line.horizontalToSuperview()
        line.height(1)
        line.bottomToSuperview()
        
    }
    
}
