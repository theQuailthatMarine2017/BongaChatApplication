//
//  RecentChatTableViewCell.swift
//  Bonga
//
//  Created by RastaOnAMission on 12/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit

protocol RecentChatTableViewCellDelegate {
    func didTappAvatarImage(indexPath: IndexPath)
}

class RecentChatTableViewCell: UITableViewCell {

    @IBOutlet weak var avartPhoto: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var recentMessage: UILabel!
    @IBOutlet weak var messageCounter: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var messageCountBg: UIView!
    
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    var delegate: RecentChatTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        messageCountBg.layer.cornerRadius = messageCountBg.frame.width / 2
        tapGesture.addTarget(self, action: #selector(self.avatarTapped))
        avartPhoto.isUserInteractionEnabled = true
        avartPhoto.addGestureRecognizer(tapGesture)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        self.fullName.text = recentChat[kWITHUSERFULLNAME] as? String
        self.recentMessage.text = recentChat[kLASTMESSAGE] as? String
        self.messageCounter.text = recentChat[kCOUNTER] as? String
        
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                
                if avatarImage != nil {
                    self.avartPhoto.image = avatarImage?.circleMasked
                }
            }
        }
        
        if recentChat[kCOUNTER] as! Int != 0 {
            self.messageCounter.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounter.isHidden = false
            self.messageCountBg.isHidden = false
        } else {
            self.messageCounter.isHidden = true
            self.messageCountBg.isHidden = true
        }
        
        var date: Date!
        
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)!
            }
        } else {
            date = Date()
        }
        
        self.date.text = timeElapsed(date: date)
        
    }
    
    @objc func avatarTapped() {
        delegate?.didTappAvatarImage(indexPath: indexPath)
    }

}
