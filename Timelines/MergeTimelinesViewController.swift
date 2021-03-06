//
//  MergeTimelinesViewController.swift
//  Timelines
//
//  Created by Princess Sampson on 10/17/16.
//  Copyright © 2016 Arcore. All rights reserved.
//

import UIKit

class MergeTimelinesViewController: UIViewController {
    @IBOutlet var friendsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friendsTableView.dataSource = self
        friendsTableView.delegate = self
        
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            print("\n\n\nTimer Ran\n\n\n")
            guard let user = UserStore.mainUser else {
                return
            }
            print("\n\n\nuser not nil\n\n\n")
            
            let request = ContactsRequest(username: user.username)
            
            API.contacts(body: request) { contactsResponse in
                guard let contacts = contactsResponse.contacts else {
                    print(contactsResponse.errorMessage)
                    return
                }
                
                for username in contacts {
                    UserStore.addContact(username: username)
                }
                
                OperationQueue.main.addOperation {
                    self.friendsTableView.reloadData()
                }
            }

        }
        
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.title = "Friends"
    }
    
    @IBAction func attemptContactRequest(_ sender: UIButton) {
        guard let user = UserStore.mainUser else {
            return
        }
        
        let alert = AlertView.createAlertWithTextField(title: "Add contact", message: "Input username of contact", actionTitle: "Cancel", "Send") { receiver in
            
            guard receiver != user.username else {
                let errorAlert = AlertView.createAlert(title: "Error", message: "Can not send request to self", actionTitle: "OK")
                self.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            let request = FriendRequest(sender: user.username, reciever: receiver)
            
            API.requestFriend(body: request) { message in
                if !receiver.isEmpty && !(receiver == "") {
                    OperationQueue.main.addOperation {
                        let messageAlert = AlertView.createAlert(title: "", message: message, actionTitle: "OK")
                        
                        self.present(messageAlert, animated: true, completion: nil)
                    }
                }
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func mergeTimelines(_ sender: UIButton) {
        if UserStore.selectedContacts.count > 1 {
            OperationQueue.main.addOperation {
                self.tabBarController?.selectedIndex = 0
            }
        }
    }
    
}

extension MergeTimelinesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserStore.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friendTuple = UserStore.contacts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell") as! FriendCell
        cell.accessoryType = .none
        cell.username.text = friendTuple.username
        
        if friendTuple.selected {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
}

extension MergeTimelinesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var friend = UserStore.contacts[indexPath.row]
        friend.selected = !friend.selected
        
        UserStore.contacts.remove(at: indexPath.row)
        UserStore.contacts.insert(friend, at: indexPath.row)
        
        tableView.reloadData()
    }
}
