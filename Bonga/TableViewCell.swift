//
//  TableViewCell.swift
//  Bonga
//
//  Created by RastaOnAMission on 06/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit

protocol TableViewDelegate {
    func didTappAvatarImage(indexPath: IndexPath)
}

class TableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    
    var indexPath: IndexPath!
    var delegate: TableViewDelegate?
    let tapped = UITapGestureRecognizer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tapped.addTarget(self, action: #selector(self.avatarTapped))
        avatarImage.isUserInteractionEnabled = true
        avatarImage.addGestureRecognizer(tapped)
    }
    
    @objc func avatarTapped() {
        delegate!.didTappAvatarImage(indexPath: indexPath)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.fullName.text = fUser.fullname
        
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { (avatarPic) in
                if avatarPic != nil {
                    self.avatarImage.image = avatarPic!.circleMasked
                }
            }
        }
    }

}
