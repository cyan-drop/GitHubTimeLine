//
//  Repository.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/28.
//  Copyright © 2019 cyan. All rights reserved.
//

import Foundation

struct Repository {
    
    var id: Int = 0
    var name: String = ""
    var repositoryDescription: String = ""
    var owner: String = ""
    var avaterUrl: String = ""
    
    init?(value: [String: Any]) {
        guard let name = value["name"] as? String,
            let description = value["description"] as? String
            else { return nil }
        guard let ownerData = value["owner"] as? [String: Any] else { return nil }
        guard let owner = ownerData["login"] as? String,
            let avaterUrl = ownerData["avatar_url"] as? String
            else { return nil}
        
        self.id = value["id"] as! Int
        self.name = name
        self.repositoryDescription = description
        self.owner = owner
        self.avaterUrl = avaterUrl
    }
    
}
