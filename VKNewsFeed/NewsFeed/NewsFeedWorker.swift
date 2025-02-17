//
//  NewsFeedWorker.swift
//  VKNewsFeed
//
//  Created by Анастасия Кудашева on 21.09.2020.
//  Copyright (c) 2020 Анастасия Кудашева. All rights reserved.
//

import UIKit

class NewsFeedService {
    
    var authService: AuthService
    var networkind: Networking
    var fether: DataFetcher
    
    private var revealedPostIds = [Int]()
    private var feedResponse: FeedResponse?
    private var newFromInProcess: String?
    
    init() {
        self.authService = SceneDelegate.shared().authService
        self.networkind = NetworkService(authService: authService)
        self.fether = NetworkDataFetcher(networking: networkind)
    }
    
    func getUser(completion: @escaping (UserResponse?) -> Void) {
        fether.getUser { ( userResponse) in
            completion(userResponse)
        }
    }
    func getFeed(completion: @escaping ([Int], FeedResponse) -> Void) {
        fether.getFeed(nextBatchFrom: nil) { [weak self] (feed) in
            self?.feedResponse = feed
            guard let feedResponse = self?.feedResponse else { return }
            
            completion(self!.revealedPostIds, feedResponse)
        }
    }
    
    func revealPostIds(forPostId postId: Int, completion: @escaping ([Int], FeedResponse) -> Void) {
        revealedPostIds.append(postId)
        guard let feedResponse = self.feedResponse else { return }
        completion(revealedPostIds, feedResponse)
    }
    func getNextBatch(completion: @escaping ([Int], FeedResponse) -> Void) {
        newFromInProcess = feedResponse?.nextFrom
        fether.getFeed(nextBatchFrom: newFromInProcess) { [weak self] (feed) in
            guard let feed = feed else { return }
            guard self?.feedResponse?.nextFrom != feed.nextFrom else { return }
            
            if self?.feedResponse == nil {
                self?.feedResponse = feed
            } else {
                self?.feedResponse?.items.append(contentsOf: feed.items)
                
                var profiles = feed.profiles
                if let oldProfiles = self?.feedResponse?.profiles {
                    let oldProfilesFiltred = oldProfiles.filter({ (oldProfile) -> Bool in
                        !feed.profiles.contains(where: { $0.id == oldProfile.id })
                    })
                    profiles.append(contentsOf: oldProfilesFiltred)
                }
                self?.feedResponse?.profiles = profiles
                
                var groups = feed.groups
                if let oldGroups = self?.feedResponse?.groups {
                    let oldGroupsFiltred = oldGroups.filter({ (oldGroup) -> Bool in
                        !feed.groups.contains(where: { $0.id == oldGroup.id })
                    })
                    groups.append(contentsOf: oldGroupsFiltred)
                }
                
                self?.feedResponse?.groups = groups
                self?.feedResponse?.nextFrom = feed.nextFrom
            }
        }
        
        guard let feedResponse = self.feedResponse else { return }
        completion(self.revealedPostIds, feedResponse)
    }
}

