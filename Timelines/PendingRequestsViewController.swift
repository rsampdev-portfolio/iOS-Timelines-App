//
//  PendingRequestsViewController.swift
//  Timelines
//
//  Created by Daniel Kwolek on 10/13/16.
//  Copyright © 2016 Arcore. All rights reserved.
//

import UIKit

enum tableControlSelected: Int {
    case received = 0
    case sent = 1
}

class PendingRequestsViewController: UIViewController {
    @IBOutlet var tableControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pollForContacts()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableControl.addTarget(tableView, action: #selector(UITableView.reloadData), for: .valueChanged)
    }
    
    func pollForContacts() {
        guard let user = UserStore.mainUser else {
            return
        }
        
        let timer = Timer(timeInterval: 5.0, repeats: true) { _ in
            print("💜timer ran")
            
            if UserStore.shouldPoll {
                let request = ContactsRequest(username: user.username)
                
                API.contactRequests(body: request) { contactRequestsResponse in
                    guard let contactRequests = contactRequestsResponse.requests else {
                        print(contactRequestsResponse.errorMessage)
                        return
                    }
                    
                    for request in contactRequests {
                        UserStore.addPending(request: request)
                    }
                }
            }
            
            OperationQueue.main.addOperation {
                print(self.tabBarController)
                print(self.tabBarController?.tabBarItem)
                self.tabBarItem.badgeColor = UIColor.red
                self.tabBarItem.badgeValue = "\(UserStore.pendingRequests.count)"
            }
        }
        
        RunLoop.main.add(timer, forMode: .commonModes)
    }
}

extension PendingRequestsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableControl.selectedSegmentIndex {
            
        case tableControlSelected.received.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PendingRequestCell") as! PendingRequestCell
            let pendingRequest = UserStore.pendingRequests[indexPath.row]
            cell.username.text = pendingRequest.username
            
            return cell
        case tableControlSelected.sent.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PendingContactCell") as! PendingContactCell
            let pendingContact = UserStore.pendingContacts[indexPath.row]
            cell.message.text = "You sent a contact request to @\(pendingContact)"
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch tableControl.selectedSegmentIndex {
        case tableControlSelected.received.rawValue:
            return UserStore.pendingRequests.count
        case tableControlSelected.sent.rawValue:
            return UserStore.pendingContacts.count
        default:
            return 0
        }
        
        
    }
}
