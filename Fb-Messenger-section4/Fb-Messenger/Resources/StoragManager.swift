//
//  StoragManager.swift
//  Fb-Messenger
//
//  Created by Hamad Wasmi on 30/03/1443 AH.
//

import Foundation
import FirebaseStorage

final class StoragManager{
    
    static let shared = StoragManager()
    
    private let storage = Storage.storage().reference()
    
    
    public func uploadProfilePic(with data: Data, file: String,  completion: @escaping(Result<String, Error>)->Void){
        storage.child("images/\(file)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else{
                print("failed to upload")
                completion(.failure(PossibleErrors.failedToUpload))//ok to change later****
                return}
            //***ok to do/try\catch instead of completion
            self.storage.child("images/\(file)").downloadURL(completion:{ url, error in
                guard let url = url else {
                    print("")
                    completion(.failure(PossibleErrors.failedToGetUrl))
                    return
                }
                let downloadedURL = url.absoluteString
                print("download url is :\(downloadedURL)")
                completion(.success(downloadedURL))
            }
            )
        })
    }
    //this just to be fancy
    public enum PossibleErrors: Error{
        case failedToUpload
        case failedToGetUrl
    }
    public func downloadImgURL(for path: String, completion: @escaping (Result<URL, Error>)-> Void){
        let ref = storage.child(path)
        ref.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(PossibleErrors.failedToGetUrl))
                return
            }
            completion(.success(url))
        })
    }
}
