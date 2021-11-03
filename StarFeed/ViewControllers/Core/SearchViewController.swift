//
//  SearchViewController.swift
//  StarFeed
//
//  Created by Forrest Buhler on 10/11/21.
//

import UIKit
import FirebaseFirestore

class SearchViewController: UIViewController, UICollectionViewDataSource, UITextFieldDelegate {

    private let fb = FirebaseModel.shared

    private var lastDoc: QueryDocumentSnapshot?
    private let titleBar = TitleBar(title: "Search", backButton: false)
    private let collectionView = CustomCollectionView()
    
    private let searchBar = CustomTextField(text: "Search...", image: "magnifyingglass")
    private let progress = ProgressView()
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // TitleBar
        titleBar.vc = self
        if let image = fb.currentUser.profileImage {
            titleBar.menuButton.setImage(image, for: .normal)
        }
        collectionView.reloadData()
    }
    
    private func setupView() {
        //View
        view.addSubview(titleBar)
        view.backgroundColor = .systemBackground
        
        //Search bar
        view.addSubview(searchBar)
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        view.addSubview(progress)
        
        //CollectionView
        collectionView.dataSource = self

        view.addSubview(collectionView)
        
        view.addSubview(noPostsLabel)
    }
 
    private func setupConstraints() {
        searchBar.topToBottom(of: titleBar, offset: 10)
        searchBar.horizontalToSuperview(insets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
        searchBar.height(50)
        
        collectionView.edgesToSuperview(excluding: .top, usingSafeArea: true)
        collectionView.topToBottom(of: searchBar, offset: 10)
        
        progress.edgesToSuperview()
        view.bringSubviewToFront(progress)
        
        noPostsLabel.centerXToSuperview()
        noPostsLabel.centerYToSuperview()
        noPostsLabel.height(50)
        noPostsLabel.horizontalToSuperview()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBar.endEditing(true)
        progress.start()
        self.search(string: searchBar.text!) { last in
            if let last = last {
                self.lastDoc = last
            }
            self.progress.stop()
            self.collectionView.reloadData()
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var posts = [Post]()
        for post in fb.posts { if post.title.contains(searchBar.text!.lowercased()) { posts.append(post) } }
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var posts = [Post]()
        for post in fb.posts { if post.title.contains(searchBar.text!.lowercased()) { posts.append(post) } }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! PostView
        cell.setupView(post: posts[indexPath.row])
        cell.vc = self
        noPostsLabel.text = ""
        return cell
    }
    
    func search(string: String, completion:@escaping (QueryDocumentSnapshot?) -> Void) {
        
        DispatchQueue.main.async {
            
            let db = Firestore.firestore().collection("posts")
                .order(by: "date")
                .whereField("title", in: [string.lowercased()])
                .limit(to: 5)
            
            let group = DispatchGroup()
            
            //Load all documents
            db.getDocuments { query, error in
                guard let query = query else {
                    completion(nil)
                    return
                }
                                                        
                for doc in query.documents {
                    
                    group.enter()
                    var postId = ""
                    let title = doc.get("title") as! String
                    if title.lowercased().contains(string.lowercased()) {
                        postId = doc.documentID
                    }
                    
                    self.fb.loadPost(postId: postId, completion: {
                        group.leave()
                    })
                }
                if self.fb.posts.count == 0 {
                    self.noPostsLabel.text = "No posts available."
                }
                group.notify(queue: .main, execute: {
                    completion(query.documents.last)
                })
            }
        }
    }
        
}



