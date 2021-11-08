//
//  ConversationTableViewCell.swift
//  Fb-Messenger
//
//  Created by Hamad Wasmi on 03/04/1443 AH.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    private let userimg: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius=50
        imgView.layer.masksToBounds=true
        return imgView
        
    }()
    private let userName: UILabel = {
       let label=UILabel()
        label.font = .systemFont(ofSize: 20)
        return label
    }()
    private let userMsg: UILabel = {
       let label=UILabel()
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines=0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle , reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: "ConversationTableViewCell")
        print(self.reuseIdentifier)
        contentView.addSubview(userimg)
        contentView.addSubview(userName)
        contentView.addSubview(userMsg)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userimg.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        userName.frame = CGRect(x: 120, y: 10, width: 220, height: 100)
        userMsg.frame = CGRect(x: 120, y: 10, width: 220, height: 100)
       
    }
    
    public func configure(with model: String){
        
    }
}
