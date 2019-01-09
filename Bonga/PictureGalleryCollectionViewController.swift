//
//  PictureGalleryCollectionViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 29/11/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class PictureGalleryCollectionViewController: UICollectionViewController {
    
    var allImages: [UIImage] = []
    var allImageLinks: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Media"
        
        if allImageLinks.count > 0 {
            downloadImages()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return  1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return allImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PictureGalleryCollectionViewCell
    
        // Configure the cell
        
        cell.generateCell(image: allImages[indexPath.row])
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photos = IDMPhoto.photos(withImages: allImages)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false
        browser?.displayToolbar = true
        browser?.setInitialPageIndex(UInt(indexPath.row))
        self.present(browser!, animated: true, completion: nil)
        
    }

    func downloadImages() {
        
        for imageLink in allImageLinks {
            downloadImage(imageUrl: imageLink) { (image) in
                if image != nil {
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }

}
