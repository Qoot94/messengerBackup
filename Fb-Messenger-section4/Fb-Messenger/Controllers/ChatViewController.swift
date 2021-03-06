

import UIKit
import MessageKit
import InputBarAccessoryView

// message model
struct Message: MessageType {
    
    public var sender: SenderType // sender for each message
    public var messageId: String // id to de duplicate
    public var sentDate: Date // date time
    public var kind: MessageKind // text, photo, video, location, emoji
}
extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
            //        case .linkPreview(_):
            //            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}
// sender model
struct Sender: SenderType {
    public var photoURL: String // extend with photo URL
    public var senderId: String
    public var displayName: String
    
}
class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    public var otherUserEmail: String! = nil
    private var conversationId: String! = nil
    public var isNewConversation = false
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {    // we cache the user email
                  return nil
        }
      
        return   Sender(photoURL: "",
                        senderId: email ,
                        displayName: "joe Smith")
    }()
    
    init(with email: String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate: Date(),
//                                kind: .text("hello World message")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
        public static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = .current
            return formatter
        }()
    
    
    //
    
    //    private var selfSender: Sender? {
    //        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
    //            // we cache the user email
    //            return nil
    //        }
    //
    //        let safeEmail = DatabaseManger.safeEmail(email)
    //
    //        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    //    }
    //    // will use sender's email address plus random ID generated and put into firebase
    //    // photo URL, we will grab that URL once uploaded
    //
    
    //    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
    //        DatabaseManger.shared.getAllMessagesForConversation(with: id) { [weak self] result in
    //            switch result {
    //            case .success(let messages):
    //                print("success in getting messages: \(messages)")
    //                guard !messages.isEmpty else {
    //                    print("messages are empty")
    //                    return
    //                }
    //                self?.messages = messages
    //
    //                DispatchQueue.main.async {
    //                    self?.messagesCollectionView.reloadDataAndKeepOffset()
    //
    //                    if shouldScrollToBottom {
    //                        self?.messagesCollectionView.scrollToLastItem()
    //
    //                    }
    //
    //                }
    //
    //            case .failure(let error):
    //                print("failed to get messages: \(error)")
    //            }
    //        }
    //    }
    //
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //        messageInputBar.inputTextView.becomeFirstResponder()
    //
    //        if let conversationId = conversationId {
    //           listenForMessages(id:conversationId, shouldScrollToBottom: true)
    //        }
    //    }
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId()  else {
            return
        }

        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))

        // Send message
        if isNewConversation {
//             create convo in database
//             message ID should be a unique ID for the given message, unique for all the message
            // use random string or random number name: self.title ?? "User",
            DatabaseManger.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMsg: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }else{
                    print("failed to send")
                }
            }
            
        }
else {
            guard let conversationId = conversationId, let name = self.title else {
                return
            }

            // append to existing conversation data
            DatabaseManger.shared.sendMsg(to: conversationId, msg: message) { success in
                if success {
                    print("message sent")
                }else {
                    print("failed to send")
                }
            }

}
    }

    private func createMessageId() -> String? {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }

        let safeCurrentEmail = DatabaseManger.safeEmail(currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail!)_\(safeCurrentEmail)_\(dateString)"


        print("created message id: \(newIdentifier)")
        return newIdentifier

    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("self sender is nil")
        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    //    func currentSender() -> SenderType {
    //        // show the chat bubble on right or left?
    //        if let sender = selfSender {
    //            return sender
    //        }
    //        fatalError("Self sender is nil, email should be cached")
    //        return Sender(photoURL: "", senderId: "12", displayName: "")
    //
    //    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section] // message kit framework uses section to separate every single message
        // a message on screen might have mulitple pieces (cleaner to have a single section per message)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}

