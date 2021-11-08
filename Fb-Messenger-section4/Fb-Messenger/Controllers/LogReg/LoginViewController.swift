//
//  LoginViewController.swift
//  Fb-Messenger
//
//  Created by Hamad Wasmi on 21/03/1443 AH.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import FacebookCore
//import FacebookShare
//import FamilyControls
import FBSDKLoginKit
import JGProgressHUD
//TODO: if email is not there, show warning.
//if nothing is entered, show warning.-> print error

class LoginViewController: UIViewController {
    //MARK: IBOutlet 
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var GoogleLoginBt: UIButton!
    @IBOutlet weak var facebookLoginBt: FBLoginButton!
    
    
    private let spinner = JGProgressHUD(style: .light)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let token = AccessToken.current,
                !token.isExpired {
                // User is logged in, do work such as go to next view controller.
            facebookLoginBt?.isEnabled = false
        }else{
            facebookLoginBt?.isEnabled = true
            facebookLoginBt?.permissions = ["public_profile", "email"]
        }
        
    }
  
    
    //MARK: Functions
    func logIn(){
        // Firebase authorized Login
        FirebaseAuth.Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: {
            [weak self] authResult, error in
            
            guard let strongSelf = self else{
                return
            }
            let userEmail = strongSelf.emailTextField.text!
            //when succeed, remove spinner in main thread
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: false)
            }
            //saftely unwrap error and results from server call
            guard let result = authResult, error == nil else {
                //handle when there is error: pop error alert to user
                strongSelf.popAlert("\(error?.localizedDescription ?? " " )")
                print("Failed to log in user with email: \(userEmail)")
                return
            }
            
            //handle when result call is successeful/no error
            let user = result.user

            print("logged in user: \(user)")
            UserDefaults.standard.set(userEmail, forKey: "email")
            //save user logged in
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.synchronize()
            strongSelf.dismiss(animated: true, completion: nil)
            
        })

    }
    
    func popAlert(_ message: String) {
       let alert = UIAlertController(title: "warning", message: message, preferredStyle: .alert)
       alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
       self.present(alert, animated: true)
   }
    
    //MARK: IBActions and user interactions
    @IBAction func LogInUser(_ sender: UIButton) {
        spinner.show(in: view)
        logIn()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
