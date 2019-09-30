//
//  TimeLineViewReactor.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/27.
//  Copyright © 2019 cyan. All rights reserved.
//

import ReactorKit
import RxCocoa
import RxSwift
import RxDataSources

typealias RepositoryListSection = SectionModel<Void, RepositoryInfoCellReactor>

final class TimeLineViewReactor: Reactor {
    
    enum Action {
        case loadRepository
        case searchRepository(String?)
        case loadNextPage
    }
    
    enum Mutation {
        case setQuery(String?)
        case setLoadingNextPage(Bool)
        case setRepos([RepositoryListSection], nextPage: Int?, error: String?)
        case appendRepos([RepositoryListSection], nextPage: Int?, error: String?)
        case setSections([RepositoryListSection], error: String?, since: Int?)
        case appendSections([RepositoryListSection], error: String?, since: Int?)
    }
    
    struct State {
        var query: String?
        var repos: [RepositoryListSection]
        var nextPage: Int?
        var since: Int?
        var isLoadingNextPage: Bool = false
        var error: String?
    }
    
    let initialState: State
    
    init() {
        self.initialState = State(
            query: nil,
            repos: [RepositoryListSection(model: Void(), items: [])],
            nextPage: 0,
            since: 0,
            isLoadingNextPage: false,
            error: ""
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        let loadRepositoryManager = LoadRepositoryManager()
      
        switch action {
        case .loadRepository:
            return Observable.concat([
                Observable.just(Mutation.setQuery("")),
                loadRepositoryManager.loadAll(since: 0)
                    .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                    .map{ repo, error in
                        let since = repo.last?.id
                        let sectionItems = repo.map(RepositoryInfoCellReactor.init)
                        let section = RepositoryListSection(model: Void(), items: sectionItems)
                        return .setSections([section], error: error, since: since)
                }])
        
        case let .searchRepository(query):
            return Observable.concat([
                Observable.just(Mutation.setQuery(query)),
                loadRepositoryManager.search(query: query, page: 1)
                    .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                    .map { repo, page, error in
                        let sectionItems = repo.map(RepositoryInfoCellReactor.init)
                        let section = RepositoryListSection(model: Void(), items: sectionItems)
                        return .setRepos([section], nextPage: page, error: error)
                }])
            
        case .loadNextPage:
            guard !self.currentState.isLoadingNextPage else { return Observable.empty() }
            guard let page = self.currentState.nextPage else { return Observable.empty() }
            
            guard let since = self.currentState.since else { return Observable.empty() }
            
            func setType() -> Observable<Mutation>{
                if page != 0 {
                    return loadRepositoryManager.search(query: self.currentState.query, page: 1)
                        .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                        .map { repo, page, error in
                            let sectionItems = repo.map(RepositoryInfoCellReactor.init)
                            let section = RepositoryListSection(model: Void(), items: sectionItems)
                            return .appendRepos([section], nextPage: page, error: error)
                    }
                } else {
                    return loadRepositoryManager
                    .loadAll(since: since)
                        .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                        .map{ repo, error in
                            let newSince = repo.last?.id
                            let sectionItems = repo.map(RepositoryInfoCellReactor.init)
                            let section = RepositoryListSection(model: Void(), items: sectionItems)
                            return .appendSections([section], error: error, since: newSince)}
                }
            }
            
            return Observable.concat([
                Observable.just(Mutation.setLoadingNextPage(true)),
                setType(),
                Observable.just(Mutation.setLoadingNextPage(false)),
                ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setQuery(query):
            state.query = query
            return state
            
        case let .setLoadingNextPage(isLoadingNextPage):
            state.isLoadingNextPage = isLoadingNextPage
            return state
            
        case let .setRepos(repos, nextPage, error):
            state.repos = repos
            state.nextPage = nextPage
            state.error = error
            return state
            
        case let .appendRepos(repos, nextPage, error):
            state.repos.append(contentsOf: repos)
            state.nextPage = nextPage
            state.error = error
            return state
            
        case let .setSections(sections, error, since):
            state.repos = sections
            state.error = error
            state.since = since
            return state
            
        case let .appendSections(sections, error, since):
            state.repos.append(contentsOf: sections)
            state.error = error
            state.since = since
            return state
        }
    }
}

extension TimeLineViewReactor.Action {
    static func isUpdateQueryAction(_ action: TimeLineViewReactor.Action) -> Bool {
        if case .searchRepository = action {
            return true
        } else {
            return false
        }
    }
}



