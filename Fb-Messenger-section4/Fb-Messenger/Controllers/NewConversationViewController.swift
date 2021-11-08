//
//  NewConversationViewController.swift
//  Fb-Messenger
//
//  Created by Hamad Wasmi on 21/03/1443 AH.
//

import UIKit
import JGProgressHUD
import simd
class NewConversationViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    public var comletionHandler: (([String:String])-> (Void))?
    private var users = [[String:String]]()
    private var results = [[String:String]]()
    private var didFetch = false
    
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "search for users.."
        return searchBar
    }()
    
    private let  table: UITableView = {
            var table = UITableView()
            table.isHidden = true // first fetch the conversations, if none (don't show empty convos)
            table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            return table
        }()
    
    private let noSearchResultLabel: UILabel = {
        let label = UILabel()
        label.text = "No Matches"
        label.isHidden = true
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.addSubview(noSearchResultLabel)
        view.addSubview(table)
        view.backgroundColor = .white
        
        table.delegate = self
        table.dataSource = self
        searchBar.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.frame=view.bounds
        noSearchResultLabel.frame=CGRect(x: view.frame.width/4, y: (view.frame.height-200)/2, width: view.frame.width/2, height: 100)
    }
    func searchForUser(query: String){
        if didFetch{
            fetchFilter(with: query)
        }
        else{
            DatabaseManger.shared.getAllUsers(completion: {[weak self] result in
                switch result{
                case .success(let Allusers):
                    self?.didFetch = true
                    self?.users=Allusers
                    self?.fetchFilter(with: query)
                case .failure(let error):
                    print("error fetching users: \(error)")
                }
            })
        }
    }
    
    func fetchFilter(with term:String){
        guard didFetch else{return}
        self.spinner.dismiss(animated: true)
        let results:[[String:String]] = self.users.filter({
            //***
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        UpdateResult()
    }
    func UpdateResult(){
        if results.isEmpty{
            self.noSearchResultLabel.isHidden = false
            self.table.isHidden = true
        }else{
            self.noSearchResultLabel.isHidden = true
            self.table.isHidden = false
            self.table.reloadData()
        }
    }
    @objc private func dismissSelf(){
        dismiss(animated: true)
    }
}

extension NewConversationViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        table.deselectRow(at: indexPath, animated: true)
        //go to chat
        let targetUser = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.comletionHandler?(targetUser)
        })
        
    }
    
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        self.searchForUser(query: text)
    }
}
