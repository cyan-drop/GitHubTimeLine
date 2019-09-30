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

final class TimeLineViewcontroller: UIViewController, UITableViewDelegate, StoryboardView {

    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var timeLineSearchBar: UISearchBar!
    @IBOutlet weak var timeLineTableView: UITableView!
        {
        didSet {
            timeLineTableView.register(UINib(nibName: "RepositoryInfoCell", bundle: nil), forCellReuseIdentifier: "repositoryInfoCell")
        }
    }
    private var refreshControl = UIRefreshControl()
    private var alertController = UIAlertController()
    
    var disposeBag = DisposeBag()
    let dataSource = RxTableViewSectionedReloadDataSource<RepositoryListSection>(
        configureCell: { _, tableView, indexPath, reactor in
            let cell = tableView.dequeueReusableCell(withIdentifier: "repositoryInfoCell", for: indexPath) as! RepositoryInfoCell
            cell.reactor = reactor
            return cell
    })
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeLineTableView.scrollIndicatorInsets.top = timeLineTableView.contentInset.top
        timeLineSearchBar.placeholder = NSLocalizedString("Search_Placeholder", comment: "")
        reactor = TimeLineViewReactor()
        
        refreshControl.backgroundColor = UIColor.lightGray
        self.timeLineTableView.addSubview(refreshControl)
  }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setAlert(message: String?) {
        self.alertController = UIAlertController(title: NSLocalizedString("Alert_Title", comment: ""),
                                                 message: message,
                                                 preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString("Alert_Load_Limit_Error_OK", comment: ""), style: UIAlertAction.Style.cancel, handler: {
            (action: UIAlertAction!) in
        })
        self.alertController.addAction(cancel)
        self.present(self.alertController, animated: true, completion: nil)
    }
    
    
    func bind(reactor: TimeLineViewReactor) {
        
        self.timeLineTableView.rx.setDelegate(self).disposed(by: self.disposeBag)
        self.dataSource.canEditRowAtIndexPath = { _, _  in true }
        self.dataSource.canMoveRowAtIndexPath = { _, _  in true }
        
        self.rx.viewDidAppear
            .map { _ in Reactor.Action.loadRepository }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        topButton.rx.tap
            .subscribe({ [weak self] _ in
                self?.timeLineTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
        
        timeLineSearchBar.rx.searchButtonClicked
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.searchRepository(self.timeLineSearchBar.text) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        timeLineSearchBar.rx.textDidBeginEditing
            .subscribe({ [weak self] _ in
                self?.timeLineTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
        
        timeLineSearchBar.rx.cancelButtonClicked
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { Reactor.Action.loadRepository }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged)
            .map { _ in Reactor.Action.loadRepository }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        refreshControl.rx.controlEvent(.valueChanged)
            .map { _ in self.refreshControl.isRefreshing }
            .filter { $0 == true }
            .bind(onNext: { [weak self] _ in
                self?.refreshControl.endRefreshing()
            })
        
        timeLineTableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let `self` = self else { return false }
                guard self.timeLineTableView.frame.height > 0 else { return false }
                return offset.y + self.timeLineTableView.frame.height >= self.timeLineTableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        reactor.state.asObservable().map { $0.repos }
            .bind(to: self.timeLineTableView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state.map { $0.error }
            .distinctUntilChanged()
            .bind(onNext: { error in
                if error != "" && error != nil {
                    self.setAlert(message: error)
                }
            })
            .disposed(by: disposeBag)
 
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
                guard let repo = reactor?.currentState.repos[indexPath.row].items[indexPath.row] else { return }
                let name = repo.initialState.name
                let owner = repo.initialState.owner
                
                guard let url = URL(string: "https://github.com/\(owner)/\(name)") else { return }
                let safariVC = SFSafariViewController(url: url)
                self.present(safariVC, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
    }
}



