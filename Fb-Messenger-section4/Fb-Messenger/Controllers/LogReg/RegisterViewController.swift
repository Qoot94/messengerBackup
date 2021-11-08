//
//  RegisterViewController.swift
//  Fb-Messenger
//
//  Created by Hamad Wasmi on 21/03/1443 AH.
//

import UIKit
import Firebase
import FirebaseAuth
import JGProgressHUD

//TODO: if email is not there, show warning.
//if nothing is entered, show warning.-> print error
//needs testing

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstNametextField: UITextField!
    @IBOutlet weak var LastNameTextField: UITextField!
    @IBOutlet weak var newEmailtextField: UITextField!
    @IBOutlet weak var newPasswordtextField: UITextField!
    @IBOutlet weak var profileIMG: UIImageView!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //profile img customization: make it round
        profileIMG.layer.cornerRadius = profileIMG.bounds.width / 2
        profileIMG.clipsToBounds=true
        profileIMG.layer.borderColor=UIColor.black.cgColor
        //placehilder customization
        // Do any additional setup after loading the view.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.profilePicPicked(tapGestureRecognizer:)))
        //imageView.isUserInteractionEnabled = true
        profileIMG.addGestureRecognizer(tapGestureRecognizer)
        
        //        DatabaseManger.shared.test("qoot", firstNametextField.text!)
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    func popAlert(_ message: String) {
        let alert = UIAlertController(title: "warning", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    //MARK: Functions
    //register a new user
    func createUser(){
        //make sure users are unique by checking if user email exists in db
        DatabaseManger.shared.userExists(with: newEmailtextField.text!, completion: {[weak self] exists in
            guard let strongSelf = self else{ return}
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: false)
            }
            guard !exists else{
                strongSelf.popAlert("the email you entered is taken, please log n or try another email")
                return
            }
            
            //if user does not exist, creat one
            Auth.auth().createUser(withEmail:strongSelf.newEmailtextField.text!, password: strongSelf.newPasswordtextField.text!, completion: {
                 authResult , error  in
                
                guard let result = authResult, error == nil else {
                    strongSelf.popAlert("\(error?.localizedDescription ?? " " )")
                    print("Error creating user\(strongSelf.newEmailtextField.text!) ,error:\(String(describing: error?.localizedDescription))")
                    return
                }
                
                //register other user data to firebase
                let userdata = ChatAppUser(firstName: strongSelf.firstNametextField.text!, lastName: strongSelf.LastNameTextField.text!, emailAddress: strongSelf.newEmailtextField.text!)
                DatabaseManger.shared.insertUser(with: userdata, completion: { success in
                    if success {
                        //upload img
                        guard let img = strongSelf.profileIMG.image, let data = img.pngData() else{return}
                        let imgfile = userdata.ProfilePicFile
                        StoragManager.shared.uploadProfilePic(with: data, file: imgfile, completion: {result in
                            switch result{
                            case .success(let downloadedURL):
                                UserDefaults.standard.set(downloadedURL, forKey: "profile_pic_url")
                                print(downloadedURL)
                            case .failure(let error):
                                print("Error storing img \(error)")
                            }
                        })
                    }
                })
                
                let user = result.user
                print("Created User: \(user)")
                strongSelf.dismiss(animated: true, completion: nil)
                let allChatvc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "allChatVC") as! ConversationsViewController
                allChatvc.modalPresentationStyle = .fullScreen
                strongSelf.present(allChatvc, animated: true, completion: nil)
                
            })
        })
    }
    //MARK: IBActions and user interactions
    //open photo picker when tab gesture happens in uiimageview
    @IBAction func profilePicPicked(tapGestureRecognizer: UITapGestureRecognizer){
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        self.presentPhotoActionSheet()
    }
    @IBAction func signUpUser(_ sender: UIButton) {
        spinner.show(in:view)
        createUser()
    }
    
}
