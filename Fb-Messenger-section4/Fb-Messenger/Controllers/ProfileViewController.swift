import FirebaseAuth
import UIKit
//needs test***
class ProfileViewController: UIViewController {
    
    @IBOutlet weak var picView: UIView!
    @IBOutlet weak var profilimg: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var VCView: UIView!
    let data = ["Log Out"]
        
    @IBOutlet weak var emailLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title=
        self.VCView = creatHeader()
    
    }
    
    func creatHeader()-> UIView?{
        guard let email = (UserDefaults.standard.value(forKey: "email") as? String) else {return nil}//***

        let safeEmail = DatabaseManger.safeEmail(email)
        //let user = DatabaseManger.
        emailLabel.text = email
        let file = "\(safeEmail)_profile_pic.png"
        let pathAddress = "images/" + file
        //safeEmail + "_profile_pic.png"
        picView.backgroundColor = .link
        let profileViewIMG = UIImageView(frame: CGRect(x: (picView.frame.width-150)/2, y: 75, width: 150, height: 150))
        //picView.contentMode = .scaleAspectFill
        picView.layer.borderWidth = 3
        picView.layer.borderColor = UIColor.white.cgColor
        picView.layer.masksToBounds = true
        
        //profileViewIMG.layer.cornerRadius = profileViewIMG.image?.size.width/2 ///***temp
        picView.addSubview(profileViewIMG)
        //UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        StoragManager.shared.downloadImgURL(for: pathAddress, completion: {
           [weak self] result in
            switch result{
            case .success(let url):
                self?.downlodIMG(img: profileViewIMG, url: url)
            case .failure(let error):
                print("failed to download img url :\(error)")
            }
        })
        return picView
    }
    
    func downlodIMG(img: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: { [self] data, _, error in
            guard let data=data, error==nil else{
                return
            }
            DispatchQueue.main.async {
                let img = UIImage(data: data)
                profilimg.image = img
            }
        }).resume()
    }
    func createName(){
        
    }
    
    
    @IBAction func signOut(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            // action that is fired once selected
            guard let strongSelf = self else {
                return
            }
            do {
                try FirebaseAuth.Auth.auth().signOut()
                // present login view controller
                let loginvc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginViewController
                loginvc.modalPresentationStyle = .fullScreen
                strongSelf.present(loginvc, animated: true, completion: nil)
            }
            catch {
                print("failed to logout")
            }
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    }
