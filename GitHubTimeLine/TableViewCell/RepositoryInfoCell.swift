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
import SDWebImage

final class RepositoryInfoCell: UITableViewCell, StoryboardView {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    typealias Reactor = RepositoryInfoCellReactor
    var disposeBag: DisposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconView.backgroundColor = UIColor.lightGray
        iconView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    // MARK: Binding
    
    func bind(reactor: Reactor) {
        nameLabel.text = reactor.currentState.name
        descriptionLabel.text = reactor.currentState.repositoryDescription
        ownerLabel.text = reactor.currentState.owner
        setAvatarFromUrl(avatar: reactor.currentState.avaterUrl)
    }
    
    private func setAvatarFromUrl(avatar: String?){
        iconView!.sd_setImage(with: URL(string: avatar!), placeholderImage: nil, options: SDWebImageOptions.refreshCached, completed: { (image, error, cacheType, imageURL) in
            if image != nil {
                self.iconView.image = image
            }
            else{
                self.iconView.image = UIImage(named: "defaultIcon")
            }
        })
    }


}

