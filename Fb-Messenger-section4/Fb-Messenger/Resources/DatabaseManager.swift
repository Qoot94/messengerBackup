

import Foundation
import FirebaseDatabase
import SwiftUI
//TODO: getAllMessagesForConversation, createNewConversation, sendMessage, uploadpicture
final class DatabaseManger {
    static let shared = DatabaseManger()
    // reference the database below
    private let database = Database.database().reference()
    
    static func safeEmail(_ emailAddress: String)-> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    // create a simple write function
    public func test() {
        // NoSQL - JSON (keys and objects)
        // child refers to a key that we want to write data to
        // in JSON, we can point it to anything that JSON supports - String, another object
        // for users, we might want a key that is the user's email address
        
        database.child("foo").setValue(["something":true])
    }
    
}
// MARK: - account management
extension DatabaseManger {
    // have a completion handler because the function to get data out of the database is asynchrounous so we need a completion block
    public func userExists(with email:String, completion: @escaping ((Bool) -> Void)) {
        // will return true if the user email does not exist
        
        // firebase allows you to observe value changes on any entry in your NoSQL database by specifying the child you want to observe for, and what type of observation you want
        // let's observe a single event (query the database once)
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            // snapshot has a value property that can be optional if it doesn't exist
            
            guard snapshot.value as? String != nil else {
                // otherwise... let's create the account
                completion(false)
                return
            }
            // if we are able to do this, that means the email exists already!
            completion(true) // the caller knows the email exists already
        }
    }
    
    /// Insert new user to database
    //    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool)->Void){
    //
    //        database.child(user.safeEmail).setValue(["first_name":user.firstName,"last_name":user.lastName], withCompletionBlock: {error , _ in
    //            guard error == nil else{
    //                print("failed to add to database ")
    //                return
    //            }
    //            completion(true)
    //        } )
    //    }
}
struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    //let profilePictureUrl: String
    
    // create a computed property safe email
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var ProfilePicFile: String{
        return "\(safeEmail)_profile_pic.png"
    }
}

extension DatabaseManger {
    
    // MARK: Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        // adding completion block here so once it's done writing to database, we want to upload the image
        // once user object is creatd, also append it to the user's collection
        database.child(user.safeEmail).setValue(["first_name":user.firstName,"last_name":user.lastName]) { error, _ in
            guard error  == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                // snapshot is not the value itself
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // if var so we can make it mutable so we can append more contents into the array, and update it append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }else{
                    //create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail,
                            "profile_img": user.ProfilePicFile
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

extension DatabaseManger{
    
    ///create conv
    public func createNewConversation(with otherUserEmail:String, name: String, firstMsg:Message ,completion: @escaping (Bool) -> Void){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManger.safeEmail(currentUserEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {snapshot in
            
            guard var userNode = snapshot.value as?[String:Any] else{
                completion(false)
                return
            }
            let messageDate = firstMsg.sentDate
            let dateStr = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMsg.kind{
            case .text(let msgText):
                message = msgText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let newConversation = ["id": firstMsg.messageId,
                                   "reciever_email": otherUserEmail,
                                   "name": name,
                                   "latest_msg": [
                                    "date":dateStr,
                                    "msg":"",
                                    "isRead":false]] as [String : Any]
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                conversations.append(newConversation)
                
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: {[weak self] error ,_ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConvos(convID: "\(firstMsg.messageId)", name:name,firstMsg: firstMsg, completion: completion)
                    
                })
            }else{
                //no convo, create new
                userNode["conversations"] = [
                    newConversation]
                ref.setValue(userNode, withCompletionBlock: {[weak self] error ,_ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConvos(convID: "\(firstMsg.messageId)", name:name, firstMsg: firstMsg, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConvos(convID: String, name:String, firstMsg:Message, completion: @escaping (Bool) -> Void){
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail=DatabaseManger.safeEmail(senderEmail)
        let messageDate = firstMsg.sentDate
        let dateStr = ChatViewController.dateFormatter.string(from: messageDate)
        var message=""
        switch firstMsg.kind{
            
        case .text(let msgText):
            message = msgText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        let msgs : [String: Any] = [
            "id":firstMsg.messageId,
            "name":name,
            "type":firstMsg.kind.messageKindString,
            "content":message,
            "senderEmail": currentUserEmail,
            "date": dateStr,
            "isRead":false
        ]
        
        let value: [String: Any] = [
            "messages":[msgs]
        ]
        database.child("\(firstMsg.messageId)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    public func getAllConversations(for email:String,completion:@escaping(Result<String,Error>)-> Void){}
    
    public func getAllMessagesForConversation(with id:String, completion: @escaping (Result<String,Error>)-> Void){}
    
    public func sendMsg(to conversation:String, msg: Message, comletion:@escaping (Bool) -> Void){}
    
    //  public func
    
    
}
// above
// when user tries to start a convo, we can pull all these users with one request
/*
 users => [
 [
 "name":
 "safe_email":
 ],
 [
 "name":
 "safe_email":
 ],
 ]
 */
// try to get a reference to an existing user's array
// if doesn't exist, create it, if it does, append to it
