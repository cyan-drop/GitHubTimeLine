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
        case setRepos([String], nextPage: Int?)
        case appendRepos([String], nextPage: Int?)
        case setLoadingNextPage(Bool)
        case setSections([RepositoryListSection])
    }
    
    struct State {
        var query: String?
        var repos: [String] = []
        var sections: [RepositoryListSection]=[]
        var nextPage: Int?
        var since: Int?
        var isLoadingNextPage: Bool = false
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        var result: Observable<Mutation>
        switch action {
        case .loadRepository:
            return Observable.concat([
                Observable.just(Mutation.setQuery("")),
                self.loadAll(since: 0)
                    .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                    .map { Mutation.setSections([RepositoryListSection(model: Void(), items: $0)]) }
                ])
            
        case let .searchRepository(query):
            return Observable.concat([
                    Observable.just(Mutation.setQuery(query)),
                    self.search(query: query, page: 1)
                        .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                        .map { Mutation.setRepos($0, nextPage: $1) },
                    ])
            
        case .loadNextPage:
            guard !self.currentState.isLoadingNextPage else { return Observable.empty() }
            guard let page = self.currentState.nextPage else { return Observable.empty() }
            
//            guard let since = self.currentState.since else { return Observable.empty() }
            
            if page != 0 {
                result = self.search(query: self.currentState.query, page: page)
                    .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                    .map { Mutation.appendRepos($0, nextPage: $1) }
            } else {
                result =  self.loadAll(since: 123)
                    .takeUntil(self.action.filter(Action.isUpdateQueryAction))
                    .map {
                        Mutation.setSections([RepositoryListSection(model: Void(), items: $0)])
                }
            }
            return result

        }
        
        
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case let .setQuery(query):
            var newState = state
            newState.query = query
            return newState
            
        case let .setRepos(repos, nextPage):
            var newState = state
            newState.repos = repos
            newState.nextPage = nextPage
            return newState
            
        case let .appendRepos(repos, nextPage):
            var newState = state
            newState.repos.append(contentsOf: repos)
            newState.nextPage = nextPage
            return newState
            
        case let .setLoadingNextPage(isLoadingNextPage):
            var newState = state
            newState.isLoadingNextPage = isLoadingNextPage
            return newState
            
        case let .setSections(sections):
            var newState = state
            print(sections)
            newState.sections = sections
            return state
        }
    }
    
    
    private func searchUrl(for query: String?, page: Int) -> URL? {
        guard let query = query, !query.isEmpty else { return nil }
        return URL(string: "https://api.github.com/search/repositories?q=\(query)&page=\(page)")
    }
    
    private func search(query: String?, page: Int) -> Observable<(repos: [String], nextPage: Int?)> {
        let emptyResult: ([String], Int?) = ([], nil)
        guard let url = self.searchUrl(for: query, page: page) else { return .just(emptyResult) }
        return URLSession.shared.rx.json(url: url)
            .map { json -> ([String], Int?) in
                
                guard let dict = json as? [String: Any] else { return emptyResult }
                guard let items = dict["items"] as? [[String: Any]] else { return emptyResult }
                let repos = items.compactMap { $0["full_name"] as? String }
                let nextPage = repos.isEmpty ? nil : page + 1
                return (repos, nextPage)
            }
            .do(onError: { error in
                if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError, response.statusCode == 403 {
                    print("⚠️ GitHub API rate limit exceeded. Wait for 60 seconds and try again.")
                }
            })
            .catchErrorJustReturn(emptyResult)
    }
    
    
    private func url() -> URL? {
        return URL(string: "https://api.github.com/repositories")
    }
    
    private func loadAll(since: Int?) -> Observable<([RepositoryInfoCellReactor])> {
        let emptyResult: [RepositoryInfoCellReactor] = []
        guard let url = self.url() else { return .just(emptyResult)}
        
        return URLSession.shared.rx.json(url: url)
            .map { json -> ([RepositoryInfoCellReactor]) in
                guard let dict = json as? [[String: Any]] else { return emptyResult }
                let ss = dict.compactMap(Repository.init)
                let sectionItems = ss.map(RepositoryInfoCellReactor.init)
//                let section = RepositoryListSection(model: Void(), items: sectionItems)
                return (sectionItems)
            }
            .do(onError: { error in
                if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError, response.statusCode == 403 {
                    print("⚠️ GitHub API rate limit exceeded. Wait for 60 seconds and try again.")
                }
            })
            .catchErrorJustReturn(emptyResult)
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

