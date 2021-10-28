//
//  FirebaseModel.swift
//  StarFeed
//
//  Created by Forrest Buhler on 10/14/21.
//

import UIKit
import FirebaseFirestore

class FirebaseModel: ObservableObject {
    
    static let shared = FirebaseModel()
    
    private let file = FileManagerModel.shared
    private let storage = StorageModel.shared
    private let cd = Persistence()
    public let db = FirestoreModel.shared
    
    @Published public var currentUser = User(id: "", username: "", name: "", profileImage: nil, following: [], followers: [], posts: [])
    @Published public var users = [User]()
    @Published public var posts = [PostView]()

    
    @Published public var subjects = [Subject]()
    
    init() {
        self.subjects = [Subject(name: "Entrepreneurship", image: "person"), Subject(name: "Career", image: "building.2"), Subject(name: "Workout", image: "heart"), Subject(name: "Confidence", image: "crown"), Subject(name: "Communication", image: "bubble.left"), Subject(name: "Motivation", image: "lightbulb"), Subject(name: "Spirituality", image: "leaf"), Subject(name: "Financial", image: "dollarsign.square"), Subject(name: "Focus", image: "scope"), Subject(name: "Happiness", image: "face.smiling"), Subject(name: "Habits", image: "infinity"), Subject(name: "Success", image: "hands.sparkles"), Subject(name: "Books/Audiobooks", image: "book"), Subject(name: "Failure", image: "cloud.heavyrain"), Subject(name: "Leadership", image: "person.3"), Subject(name: "Relationships", image: "figure.wave"), Subject(name: "Will Power", image: "battery.100.bolt"), Subject(name: "Mindfulness", image: "rays"), Subject(name: "Purpose", image: "sunrise"), Subject(name: "Time Management", image: "clock"), Subject(name: "Goals", image: "target")].sorted { $0.name < $1.name }
    }
    
    func likePost(currentPost: Post) {
        
        if !currentPost.likes.contains(currentUser.id) {
            //Save the users current ID to the likes on the post, so we can later get the number of people who have liked the post.
            db.save(collection: "posts", document: currentPost.id, field: "likes", data: [self.currentUser.id])
        } else {
            Firestore.firestore().collection("posts").document(currentPost.id).updateData(["likes": FieldValue.arrayRemove([currentUser.id])])
        }
    }
    
    func commentOnPost(currentPost: Post, comment: String, completion: @escaping () -> Void) {
        
        //Save comments when someone comments on a post
        self.saveDeepCollection(collection: "posts", collection2: "comments", document: currentPost.id, document2: currentUser.id, field: "comments", data: [comment]) {
            completion()
        }
        
    }
    
    func loadComments(currentPost: Post, completion:@escaping ([Comment]?) -> Void) {
        self.getDocsDeep(collection: "posts", document: currentPost.id, collection2: "comments") { userDocs in
            
            if let userDocs = userDocs {
                var list: [Comment] = []
                
                if !userDocs.documents.isEmpty {
                    completion(nil)
                }
                let group = DispatchGroup()
                for doc in userDocs.documents {
                    group.enter()
                    self.loadConservativeUser(uid: doc.documentID) { user in
                        let comments = doc.get("comments") as! [String]
                        if let user = user {
                            for comment in comments {
                                list.append(Comment(text: comment, user: user))
                            }
                            group.leave()
                        } else {
                            group.leave()
                        }
                    }
                }
                group.notify(queue: .main) {
                    if list.isEmpty {
                        completion(nil)
                    } else {
                        completion(list)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func getDocsDeep(collection: String, document: String, collection2: String, completion:@escaping (QuerySnapshot?) -> Void) {
        //Load Documents
        Firestore.firestore().collection(collection).document(document).collection(collection2).getDocuments { docs, error in
            
            //Check for error
            if error == nil {
                
                //Return documents
                completion(docs)
            } else {
                completion(nil)
            }
        }
    }
    
    func saveDeepCollection(collection: String, collection2: String, document: String, document2: String, field: String, data: Any, completion:@escaping () -> Void) {
        
        let document = Firestore.firestore().collection(collection).document(document).collection(collection2).document(document2)
        
        document.getDocument { doc, error in
            if doc != nil && error == nil {
                // Check if data is an array
                if let array = data as? [String] {
                    //Append data in firestore
                    if doc?.get("comments") != nil {
                        document.updateData([field: FieldValue.arrayUnion(array)])
                        completion()
                    } else {
                        document.setData([field: data])
                        completion()
                    }
                    
                    
                    // Check if data is a string
                } else if let string = data as? String {
                    //Save data in firestore
                    document.setValue(string, forKey: field)
                    
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func followUser(followUser: User, completion:@escaping () -> Void) {
        if !currentUser.following.contains(followUser.id) {
            //Follow the user
            
            //Save who the user followed
            db.save(collection: "users", document: currentUser.id, field: "following", data: [followUser.id])
            
            //Save that the followed user got followed
            db.save(collection: "users", document: followUser.id, field: "followers", data: [currentUser.id])
            
            //Add to UserModel
            self.currentUser.following.append(followUser.id)
            
            //Save to core data
            let coreUser = cd.fetchUser(uid: currentUser.id)
            coreUser?.following?.append(followUser.id)
            cd.save()
            
            completion()
            
        } else {
            // Unfollow user
            Firestore.firestore().collection("users").document(followUser.id).updateData(["followers": FieldValue.arrayRemove([currentUser.id])])
            Firestore.firestore().collection("users").document(currentUser.id).updateData(["following": FieldValue.arrayRemove([followUser.id])])
            
            // Delete from UserModel
            let index = currentUser.following.firstIndex(of: followUser.id)
            currentUser.following.remove(at: index!)
            
            //Save to core data
            let deleteCoreUser = cd.fetchUser(uid: currentUser.id)
            let newIndex = deleteCoreUser?.following?.firstIndex(of: followUser.id)
            deleteCoreUser?.following?.remove(at: newIndex!)
            cd.save()
            
            completion()
            
        }
        
    }
    
    func search(string: String, completion:@escaping () -> Void) {
        
        DispatchQueue.main.async {
            
            let group = DispatchGroup()
            //Load all documents
            self.db.getDocs(collection: "posts") { query in
                
                var postsArray = [PostView]()
                
                for doc in query!.documents {
                    
                    group.enter()
                    var postId = ""
                    let title = doc.get("title") as! String
                    if title.lowercased().contains(string.lowercased()) {
                        postId = doc.documentID
                    }
                    
                    self.loadPost(postId: postId, completion: {
                        
                        if let index = self.posts.firstIndex(where: { pview in
                            pview.post.id == postId
                            
                        }) {
                            postsArray.append(self.posts[index])
                        }
                        
                        
                        group.leave()
                    })
                }
                
                group.notify(queue: .main, execute: {
                    for post in postsArray {
                        if !self.posts.contains(where: { pview in
                            pview.post.id == post.post.id }) {
                            self.posts.append(post)
                            self.posts.sort { p1, p2 in
                                p1.post.date.timeIntervalSince1970 < p1.post.date.timeIntervalSince1970
                            }
                        }
                    }
                    completion()
                })
            }
        }
    }
    
    func loadPost(postId: String, completion:@escaping () -> Void) {
        
        if self.posts.contains(where: { pview in
            pview.post.id == postId
        }) {
            completion()
        } else {

            //Load Post Firestore Document
            self.db.getDoc(collection: "posts", id: postId) { document in
                
                
                if let doc = document {
                    guard let title = doc.get("title") as? String else {
                        completion()
                        return
                    }
                    let postId = doc.documentID
                    guard let subjects = doc.get("subjects") as? [String] else {
                        completion()
                        return
                    }
                    guard let date = doc.get("date") as? String else {
                        completion()
                        return
                    }
                    guard let uid = doc.get("uid") as? String else {
                        completion()
                        return
                    }
                    guard let likes = doc.get("likes") as? [String] else {
                        completion()
                        return
                    }
                    guard let description = doc.get("description") as? String else {
                        completion()
                        return
                    }
                    
                    //Load user for post
                    self.loadConservativeUser(uid: uid) { user in
                        
                        //Load image
                        self.storage.loadImage(path: "images", id: doc.documentID) { image in
                            
                            //Load Movie
                            self.storage.loadMovie(path: "videos", file: "\(doc.documentID).m4v") { url in
                                //Add to view model
                                
                                if let image = image, let url = url, let user = user {
                                    let dateFormat = DateFormatter()
                                    dateFormat.dateStyle = .full
                                    dateFormat.timeStyle = .full
                                    guard let dateFormatted = dateFormat.date(from: date) else { return }
                                    let post = (Post(id: postId, image: image, title: title, subjects: subjects, date: dateFormatted, uid: user.id, likes: likes, movie: url, description: description))
                                    self.posts.append(PostView(post: post))
                                    self.posts.sort { p1, p2 in
                                        p1.post.date.timeIntervalSince1970 < p1.post.date.timeIntervalSince1970
                                    }
                                    
                                    completion()
                                } else {
                                    completion()
                                }
                            }
                        }
                    }
                } else {
                    completion()
                }
            }
        }
    }
    
    func loadPosts(completion:@escaping () -> Void) {
        
        //Load all Post Firestore Documents
        self.db.getDocs(collection: "posts") { query in
            
            //Check if local loaded posts is equal to firebase docs
            if self.posts.count != query?.count {
                
                let group = DispatchGroup()
                //Loop through each document and get data
                var posts = [PostView]()
                for post in query!.documents {
                    group.enter()
                    let title = post.get("title") as! String
                    let postId = post.documentID
                    let subjects = post.get("subjects") as! [String]
                    let date = post.get("date") as! String
                    let uid = post.get("uid") as! String
                    let likes = post.get("likes") as! [String]
                    let description = post.get("description") as! String
                    
                    //Load user for post
                    self.loadConservativeUser(uid: uid) { user in
                        
                        //Load image
                        self.storage.loadImage(path: "images", id: post.documentID) { image in
                            
                            //Load Movie
                            self.storage.loadMovie(path: "videos", file: "\(post.documentID).m4v") { url in
                                //Add to view model
                                
                                if let image = image, let url = url, let user = user {
                                    let dateFormat = DateFormatter()
                                    dateFormat.dateStyle = .full
                                    dateFormat.timeStyle = .full
                                    guard let dateFormatted = dateFormat.date(from: date) else {
                                        group.leave()
                                        return
                                    }
                                    let post = (Post(id: postId, image: image, title: title, subjects: subjects, date: dateFormatted, uid: user.id, likes: likes, movie: url, description: description))
                                    posts.append(PostView(post: post))
                                }
                                group.leave()
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    self.posts = posts
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func loadUser(uid: String, completion:@escaping (User?) -> Void) {
        if let user = self.users.first(where: { users in
            users.id == uid
        }) {
            print("Loaded User From Model")
            completion(user)
        } else {
            
            //Check if can load from Core Data
            if let user = cd.fetchUser(uid: uid) {
                print("Loaded User From Core Data")
                
                if let profileImage = self.file.getFromFileManager(name: uid) {
                    let user = User(id: user.id!, username: user.username!, name: user.name!, profileImage: profileImage, following: user.following!, followers: user.followers! ,posts: user.posts!)
                    completion(user)
                    if !self.users.contains(where: { users in
                        user.id == users.id
                    }) {
                        self.users.append(user)
                    }
                } else {
                    let user = User(id: user.id!, username: user.username!, name: user.name!, profileImage: nil, following: user.following!, followers: user.followers! ,posts: user.posts!)
                    completion(user)
                    if !self.users.contains(where: { users in
                        user.id == users.id
                    }) {
                        self.users.append(user)
                    }
                }
                
            } else {
                
                //Load Firestore doc
                db.getDoc(collection: "users", id: uid) { doc in
                    
                    print("Loaded User From Firebase")
                    
                    
                    let username = doc?.get("username") as! String
                    let name = doc?.get("name") as! String
                    let following = doc?.get("following") as! [String]
                    let followers = doc?.get("followers") as! [String]
                    let posts = doc?.get("posts") as! [String]
                    
                    //Load Profile Image
                    self.storage.loadImage(path: "Profile Images", id: uid) { profileImage in
                        
                        //Create User
                        let user = User(id: uid, username: username, name: name, profileImage: profileImage, following: following, followers: followers, posts: posts)
                        if !self.users.contains(where: { users in
                            user.id == users.id
                        }) {
                            self.users.append(user)
                        }
                        
                        //Return User
                        completion(user)
                    }
                }
            }
            
        }
        
        
    }
    
    func addPost(image: UIImage, title: String, subjects: [String], movie: URL, description: String?) {
        
        // Make sure they have a description
        var desc = ""
        if description != nil {
            desc = description!
        }
        
        //Find Date
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .full
        dateFormat.timeStyle = .full
        let dateString = dateFormat.string(from: Date())
        
        //Save Post to Firestore
        let dict = ["title": title, "subjects": subjects, "uid": self.currentUser.id, "date": dateString, "likes": [], "description": desc] as [String : Any]
        self.db.newDoc(collection: "posts", document: nil, data: dict) { postId in
            
            //Save postId to User
            self.db.save(collection: "users", document: self.currentUser.id, field: "posts", data: [postId!])
            
            //Save to filemanager
            self.file.saveImage(image: image, name: postId!)
            
            //Save Image to Firebase Storage
            self.storage.saveImage(path: "images", file: postId!, image: image)
            
            //Save movie to Firestore
            self.storage.saveMovie(path: "videos", file: postId!, url: movie)
            
            //Save to core data
            if let current = self.cd.fetchUser(uid: self.currentUser.id) {
                current.posts?.append(postId!)
            }
        }
    }
    
    func loadConservativeUser(uid: String, completion:@escaping (User?) -> Void) {
        
        if let user = self.users.first(where: { users in users.id == uid }) {
            print("Loaded User From Model")
            completion(user)
        } else {
            //Check if can load from Core Data
            if let user = cd.fetchUser(uid: uid) {
                
                print("Loaded User From Core Data")
                
                
                if let profileImage = self.file.getFromFileManager(name: uid) {
                    completion(User(id: user.id!, username: user.username!, name: user.name!, profileImage: profileImage, following: user.following!, followers: user.followers!, posts: user.posts!))
                } else {
                    completion(User(id: user.id!, username: user.username!, name: user.name!, profileImage: nil, following: user.following!, followers: user.followers!, posts: user.posts!))
                }
                
            } else {
                
                //Load Firestore doc
                self.db.getDoc(collection: "users", id: uid) { doc in
                    
                    print("Loaded User From Firebase")
                    
                    guard let username = doc?.get("username") as? String else { return }
                    
                    //Load Profile Image
                    self.storage.loadImage(path: "Profile Images", id: uid) { profileImage in
                        
                        
                        //Create User
                        let user = User(id: uid, username: username, name: nil, profileImage: profileImage, following: [], followers: [], posts: [])
                        self.users.append(user)
                        
                        //Return User
                        completion(self.users.last)
                    }
                }
            }
        }
    }
}


