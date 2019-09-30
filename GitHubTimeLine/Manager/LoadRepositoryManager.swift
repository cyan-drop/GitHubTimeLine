//
//  LoadRepositoryManager.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/29.
//  Copyright © 2019 cyan. All rights reserved.
//

import Foundation
import RxSwift
import ReactorKit
import RxCocoa


private let gitHubDomain = "https://api.github.com/"
private let listAllPublic = "repositories"
private let searchRepos = "search"


class LoadRepositoryManager: NSObject {

    override init() {
        super.init()
    }

    func loadAll(since: Int?) -> Observable<(repos: [Repository], error: String?)> {
        var emptyResult: ([Repository], String?) = ([], nil)
        
        var addSince: String = ""
        if since != 0 {
            addSince = "since=\(since!)"
        }
        let url = URL(string: "\(gitHubDomain)\(listAllPublic)?\(addSince)")!

        return URLSession.shared.rx.json(url: url)
            .map { json -> ([Repository], String?) in
                guard let dict = json as? [[String: Any]] else { return emptyResult }
                let repository = dict.compactMap(Repository.init)
                return (repository, nil)
            }
            .catchError({ error in
                if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError, response.statusCode == 403 {
                    emptyResult = ([], NSLocalizedString("Alert_Load_Limit_Error", comment: ""))
                }
                return .just(emptyResult)
            })
    }

    func search(query: String?, page: Int) -> Observable<(repos: [Repository], nextPage: Int?, error: String?)> {
        var emptyResult: ([Repository], Int?, String?) = ([], nil, nil)
        
        guard let query = query else {
            return Observable.just(emptyResult)
        }
        
        let url = URL(string: "\(gitHubDomain)\(searchRepos)/\(listAllPublic)?q=\(query)&page=\(page)")!
        return URLSession.shared.rx.json(url: url)
            .map { json -> ([Repository], Int?, String?) in
                
                guard let dict = json as? [String: Any] else { return emptyResult }
                guard let items = dict["items"] as? [[String: Any]] else { return emptyResult }
                
                let repository = items.compactMap(Repository.init)
                let nextPage = repository.isEmpty ? nil : page + 1
                return (repository, nextPage, nil)
            }
            .catchError({ error in
                if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError, response.statusCode == 403 {
                    emptyResult = ([], nil, NSLocalizedString("Alert_Load_Limit_Error", comment: ""))
                }
                return .just(emptyResult)
            })
    }
}


