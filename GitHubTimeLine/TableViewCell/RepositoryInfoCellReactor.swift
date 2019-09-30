//
//  RepositoryInfoCellReactor.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/28.
//  Copyright © 2019 cyan. All rights reserved.
//

import ReactorKit

final class RepositoryInfoCellReactor: Reactor {
    
    typealias Action = NoAction
    
    let initialState: Repository
    
    init(repos: Repository) {
        self.initialState = repos
    }
}
