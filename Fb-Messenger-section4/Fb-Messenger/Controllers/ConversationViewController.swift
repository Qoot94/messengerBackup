import UIKit
import FirebaseAuth
import JGProgressHUD

struct conversation {
    let id:String
    let name:String
    let recieverEmail:String
    let lattestMsg: LatestMsg
}
struct LatestMsg{
    let date: String
    let text:String
    let isRead:Bool
}
class ConversationsViewController: UIViewController {
    // root view controller that gets instantiated when app launches
    // check to see if user is signed in using ... user defaults
    // they are, stay on the screen. If not, show the login screen
    //sec7
    private let spinner = JGProgressHUD(style: .dark)
    private let conversations=[conversation]()
    
    private let  table: UITableView = {
            var table = UITableView()
            table.isHidden = true // first fetch the conversations, if none (don't show empty convos)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        //table.register(ConversationTableViewCell.self, forCellReuseIdentifier: "ConversationTableViewCell")
            return table
        }()
        
        private let noConversationsLabel: UILabel = {
            let label = UILabel()
            label.text = "No conversations"
            label.textAlignment = .center
            label.textColor = .gray
            label.font = .systemFont(ofSize: 21, weight: .medium)
            return label
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.addSubview(table)
        view.addSubview(noConversationsLabel)
        setupTableView()
        fetchConversations()
     
        //conversation vc is root, if user is not logged in, signout
        do {
            try FirebaseAuth.Auth.auth().signOut()
        }
        catch {
        }
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        validateAuth()
//        if UserDefaults.standard.value(forKey: "isLoggedIn") != nil{
//               let allChatvc = storyboard?.instantiateViewController(withIdentifier: "allChatVC") as! ConversationsViewController
//               self.present(allChatvc, animated: true, completion: nil)
//           }else{
//               let loginvc=storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginViewController
//               present(loginvc, animated: true, completion: nil)
//           }
    }
    private func validateAuth(){
        // current user is set automatically when you log a user in
//        if UserDefaults.standard.value(forKey: "isLoggedIn") != nil{
//               let allChatvc = storyboard?.instantiateViewController(withIdentifier: "allChatVC") as! ConversationsViewController
//               self.present(allChatvc, animated: true, completion: nil)
//        }else{
//            let loginvc=storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginViewController
//            loginvc.modalPresentationStyle = .fullScreen
//            present(loginvc, animated: true, completion: nil)
//            
//        }
        if FirebaseAuth.Auth.auth().currentUser == nil {
            // present login view controller
            let loginvc=storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginViewController
            loginvc.modalPresentationStyle = .fullScreen
            present(loginvc, animated: true, completion: nil)
            
        }
    }
}
extension ConversationsViewController{
        @objc private func didTapComposeButton(){
            // present new conversation view controller
            // present in a nav controller

            let vc = NewConversationViewController()
            vc.comletionHandler = { [weak self] result in
                self?.creatNewConversation(result: result)
            }
            let navVC = UINavigationController(rootViewController: vc)
            present(navVC,animated: true)
        }
    public func creatNewConversation(result: [String:String]){
        guard let name=result["name"], let email=result["email"] else{return}
        
        let vc = ChatViewController(with: email)
         vc.title = name
        vc.isNewConversation = true
         vc.navigationItem.largeTitleDisplayMode = .never
       navigationController?.pushViewController(vc, animated: true)
    }
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            table.frame = view.bounds
        }
    
        
        private func setupTableView(){
            
            table.delegate = self
            table.dataSource = self
        }
        
        private func fetchConversations(){
            // fetch from firebase and either show table or label
            
            table.isHidden = false
        }
    }
    extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 1
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Hello World"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        // when user taps on a cell, we want to push the chat screen onto the stack
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)// highlight what we select
        
            let vc = ChatViewController(with: "f@email.com")
            vc.title = "Jenny Smith"
            vc.navigationItem.largeTitleDisplayMode = .never
          navigationController?.pushViewController(vc, animated: true)
            //***might be better
            //let chatVC=storyboard?.instantiateViewController(withIdentifier: "chatVC") as! ChatViewController
           //
           //            present(chatVC, animated: true, completion: nil)
           //            chatVC.modalPresentationStyle = .fullScreen
        }
    }
    

