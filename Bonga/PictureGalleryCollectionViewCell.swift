//
//  PictureGalleryCollectionViewCell.swift
//  Bonga
//
//  Created by RastaOnAMission on 29/11/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit

class PictureGalleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var pictureItem: UIImageView!
    
    func generateCell(image: UIImage) {
        self.pictureItem.image = image
    }
}
