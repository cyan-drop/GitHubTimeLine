//
//  TimeLineViewcontroller.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/27.
//  Copyright © 2019 cyan. All rights reserved.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import RxViewController
import SafariServices
import RxDataSources
import ReusableKit

final class TimeLineViewcontroller: UIViewController, StoryboardView {
    
    @IBOutlet weak var timeLineTableView: UITableView!
//        {
//        didSet {
//            timeLineTableView.register(UINib(nibName: "RepositoryInfoCell", bundle: nil), forCellReuseIdentifier: "repositoryInfoCell")
//        }
//    }
    @IBOutlet weak var timeLineSearchBar: UISearchBar!
    
    var disposeBag = DisposeBag()

    
    struct Reusable {
        static let repositoryInfoCell = ReusableCell<RepositoryInfoCell>()
    }
    
    
    // MARK: Properties
    let dataSource = RxTableViewSectionedReloadDataSource<RepositoryListSection>(
        configureCell: { _, tableView, indexPath, reactor in
            let cell = tableView.dequeue(Reusable.repositoryInfoCell, for: indexPath)
            cell.reactor = reactor
            return cell
    })
//
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeLineTableView.scrollIndicatorInsets.top = timeLineTableView.contentInset.top
        timeLineSearchBar.placeholder = "Search repositry"
        reactor = TimeLineViewReactor()
        
        timeLineTableView.register(Reusable.repositoryInfoCell)
  }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    func bind(reactor: TimeLineViewReactor) {
        
        self.rx.viewWillAppear
            .map { _ in Reactor.Action.loadRepository }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        timeLineSearchBar.rx.searchButtonClicked
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.searchRepository(self.timeLineSearchBar.text) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        timeLineSearchBar.rx.cancelButtonClicked
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.loadRepository }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        timeLineTableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let `self` = self else { return false }
                guard self.timeLineTableView.frame.height > 0 else { return false }
                return offset.y + self.timeLineTableView.frame.height >= self.timeLineTableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        
        
//        reactor.state.map { $0.repos }
//            .bind(to: timeLineTableView.rx.items(cellIdentifier: "repositoryInfoCell", cellType: RepositoryInfoCell.self)) { row, repo, cell in
//                cell.nameLabel.text = re
//
//            }
//        .disposed(by: disposeBag)
        
//        self.timeLineTableView.rx.setDelegate(self).disposed(by: self.disposeBag)
        
//        reactor.state.map { $0.sections }
//            .bind(to: self.timeLineTableView.rx.items(cellIdentifier: "repositoryInfoCell", cellType: RepositoryInfoCell.self)) { row, repo, cell in
//                }
//                .disposed(by: self.disposeBag)
        
        reactor.state.map { $0.sections }
            .bind(to: self.timeLineTableView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state.map { $0.query }
            .distinctUntilChanged()
            .map { $0 ?? "" }
            .bind(to: timeLineSearchBar.rx.text)
            .disposed(by: disposeBag)
        
        timeLineTableView.rx.itemSelected
            .subscribe(onNext: { [weak self, weak reactor] indexPath in
                guard let `self` = self else { return }
                self.view.endEditing(true)
                self.timeLineTableView.deselectRow(at: indexPath, animated: false)
                guard let repo = reactor?.currentState.repos[indexPath.row] else { return }
                guard let url = URL(string: "https://github.com/\(repo)") else { return }
                let safariVC = SFSafariViewController(url: url)
                self.present(safariVC, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

extension TimeLineViewcontroller: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}


