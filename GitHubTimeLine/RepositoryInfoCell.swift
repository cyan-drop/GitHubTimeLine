//
//  RepositoryInfoCell.swift
//  GitHubTimeLine
//
//  Created by Rinna Izumi on 2019/09/28.
//  Copyright © 2019 cyan. All rights reserved.
//


import UIKit

import ReactorKit
import RxSwift
import RxCocoa

final class RepositoryInfoCell: UITableViewCell, View {
    
//    typealias Reactor = RepositoryInfoCellReactor
    
    var disposeBag = DisposeBag()
    private let nameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialize()
        
        nameLabel.font = Font.nameLabel
        nameLabel.textColor = Color.nameLabelText
        nameLabel.numberOfLines = Constant.nameLabelNumberOfLines
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Constants
    
    struct Constant {
        static let nameLabelNumberOfLines = 2
    }
    
    struct Metric {
        static let cellPadding = 15
    }
    
    struct Font {
        static let nameLabel = UIFont.systemFont(ofSize: 14)
    }
    
    struct Color {
        static let nameLabelText = UIColor.black
    }
    
    
    func initialize() {
        self.contentView.addSubview(self.nameLabel)
    }
    
    func bind(reactor: RepositoryInfoCellReactor) {
        reactor.state.map { $0.repoInfo }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (repoInfo) in
                self?.nameLabel.text = repoInfo.name
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
}

