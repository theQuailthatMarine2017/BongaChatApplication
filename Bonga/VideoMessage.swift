//
//  VideoMessage.swift
//  Bonga
//
//  Created by RastaOnAMission on 23/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class VideoMessage: JSQMediaItem {
    
    var image: UIImage?
    var videoImageView: UIImageView?
    var status: Int?
    var fileUrl: NSURL?
    
    init(withFileUrl: NSURL, maskOutGoing: Bool) {
        
        super.init(maskAsOutgoing: maskOutGoing)
        
        fileUrl  = withFileUrl
        videoImageView = nil
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) not implemented")
        
    }
    
    override func mediaView() -> UIView! {
        
        if let st = status {
            
            if st == 1 {
                return nil
            }
            
            if st == 2 && (self.videoImageView == nil) {
                
                let size = self.mediaViewDisplaySize()
                let outgoing = self.appliesMediaViewMaskAsOutgoing
                
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: UIColor.flatSkyBlue())
                
                let iconView = UIImageView(image: icon)
                
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                iconView.contentMode = .center
                
                let imageView = UIImageView(image: self.image)
                
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.addSubview(iconView)
                
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                
                self.videoImageView = imageView
                
                
            }
            
        }
        
        return self.videoImageView
    }
    
}
