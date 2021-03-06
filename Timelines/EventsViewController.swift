//
//  EventsViewController.swift
//  Timelines
//
//  Created by Daniel Kwolek on 10/13/16.
//  Copyright © 2016 Arcore. All rights reserved.
//

import UIKit

enum CellForEvent {
    case event(UserEventCell)
    case friendEvent(FriendEventCell)
    case privateFriendEvent
}

class EventsViewController: UIViewController, LoginViewControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    var weeklyTimeblocks: [Timeblock] {
        let now: Date = {
            return Date(timeIntervalSinceReferenceDate: floor((Date().timeIntervalSinceReferenceDate / 60.0)) * 60)
        }()
        let endOfWeek = now.addingTimeInterval(60 * 60 * 24 * 7)
        
        var timeblocks: [Timeblock] = TimeblockStore.timeblocks.flatMap {
            let timeblock = $0
            
            if timeblock.end < now {
                return nil
            }
            
            if timeblock.start < now {
                if let event = timeblock as? Event {
                    return event
                } else {
                    return Timeblock(start: now, end: timeblock.end)
                }
            }
            
            if timeblock.start > endOfWeek {
                return nil
            }
            
            return timeblock
        }
        
        let firstTimeblock = timeblocks.first
        let lastTimeblock = timeblocks.last
        
        guard !timeblocks.isEmpty else {
            return [Timeblock(start: now, end: endOfWeek)]
        }
        
        if (firstTimeblock?.start)! > now {
            let newFirstTimeblock = Timeblock(start: now, end: (firstTimeblock?.start)!)
            timeblocks.insert(newFirstTimeblock, at: 0)
        }
        
        if (lastTimeblock?.end)! < endOfWeek {
            let newLastTimeblock = Timeblock(start: (lastTimeblock?.end)!, end: endOfWeek)
            timeblocks.append(newLastTimeblock)
        }
        
        return timeblocks
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        guard UserStore.mainUser != nil else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            loginVC.delegate = self
            present(UINavigationController.init(rootViewController: (loginVC)), animated: false, completion: nil)
            return
        }
        self.getRecentEvents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.title = "This Week"
        self.getRecentEvents()
    }
    
    private func getRecentEvents() {
        guard UserStore.mainUser != nil else {
            return
        }
        
        let request = MergeTimelinesRequest(usernames: UserStore.selectedContacts)
        
        API.mergeTimelines(body: request) { eventsResponse in
            guard let timeblocks = eventsResponse.timeblocks else {
                return
            }
            
            TimeblockStore.timeblocks = timeblocks
            
            OperationQueue.main.addOperation {
                self.tableView.reloadData()
            }
        }
    }
    
}

extension EventsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let cell = tableView.cellForRow(at: indexPath)
        let timeblock = self.weeklyTimeblocks[indexPath.row]
        
        switch cell {
        case is UserEventCell, is FriendEventCell:
            let event = timeblock as! Event
            
            if event.isPrivate {
                return
            }
            
            let eventInfoView = storyBoard.instantiateViewController(withIdentifier: "EventInfoViewController") as! EventInfoViewController
            eventInfoView.event = event
            show(eventInfoView, sender: nil)
        default:
            let newEventView = storyBoard.instantiateViewController(withIdentifier: "NewEventViewController") as! NewEventViewController
            newEventView.timeblock = timeblock
            newEventView.timeblockIndex = self.weeklyTimeblocks.index(of: self.weeklyTimeblocks[indexPath.row])
            show(newEventView, sender: nil)
        }
    }
}

extension EventsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weeklyTimeblocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let timeblock = self.weeklyTimeblocks[indexPath.row]
        
        switch timeblock {
        case let event as Event:
            
            let dates = DateTools.eventsView(start: event.start, end: event.end)
            
            guard UserStore.mainUser!.username == event.owner.username else {
                let friendEventCell = tableView.dequeueReusableCell(withIdentifier: "FriendEventCell") as! FriendEventCell
                
                friendEventCell.title.text = event.isPrivate ? "private event" : event.name
                
                friendEventCell.username.text = event.owner.username
                friendEventCell.date.text = dates.date
                friendEventCell.startAndEndTime.text = dates.startToEnd
                
                friendEventCell.backgroundColor = UIColor.timelines_darkBlue
                friendEventCell.tintColor = UIColor.white
                
                return friendEventCell
            }
            
            let eventCell = tableView.dequeueReusableCell(withIdentifier: "UserEventCell") as! UserEventCell
            
            eventCell.title.text = event.name
            eventCell.date.text = dates.date
            eventCell.startAndEndTime.text = dates.startToEnd
            
            eventCell.backgroundColor = UIColor.timelines_lightBlue
            return eventCell
        default:
            let timeblockCell = tableView.dequeueReusableCell(withIdentifier: "TimeblockCell") as! TimeblockCell
            let dates = DateTools.eventsView(start: timeblock.start, end: timeblock.end)
            
            timeblockCell.date.text = dates.date
            timeblockCell.startAndEndTime.text = dates.startToEnd
            
            timeblockCell.tintColor = UIColor.timelines_lightBlue
            timeblockCell.backgroundColor = UIColor.white
            
            return timeblockCell
        }
        
    }
    
    func loginViewController(_ vc: LoginViewController, didFinishLogin user: User) {
        UserStore.mainUser = user
        vc.dismiss(animated: true, completion: nil)
        let pendingVC = self.tabBarController?.viewControllers?[2] as! PendingRequestsViewController
        pendingVC.pollForContacts()
    }
    
}
