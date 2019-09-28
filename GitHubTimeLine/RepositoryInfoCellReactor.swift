//
//  RepositoryInfoCellReactor.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/28.
//  Copyright © 2019 cyan. All rights reserved.
//

import ReactorKit
//import RxCocoa
//import RxSwift

final class RepositoryInfoCellReactor: Reactor {
    
//    typealias Action = NoAction
//
//    let initialState: Repository
//
//    init(repository: Repository) {
//        self.initialState = repository
//    }
    
    enum Action {}
    
    
    struct State {
        let repoInfo: Repository
    }
    
    let initialState: RepositoryInfoCellReactor.State
    
    init(_ repoInfo: Repository) {
        initialState = State(repoInfo: repoInfo)
    }
}
