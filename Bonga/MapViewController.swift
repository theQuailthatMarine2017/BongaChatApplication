//
//  MapViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 26/11/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    
    @IBOutlet weak var map: MKMapView!
    var location: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Location"
        // Do any additional setup after loading the view.
        setUpUI()
    }
    
    func setUpUI() {
        
        var region = MKCoordinateRegion()
        region.center.longitude = location.coordinate.longitude
        region.center.latitude = location.coordinate.latitude
        
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        map.setRegion(region, animated: true)
        map.showsUserLocation = true
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        map.addAnnotation(annotation)
        createRightBarButton()
    }
    
    func createRightBarButton() {
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open in Maps", style: .plain, target: self, action: #selector(self.openInMaps))]
        
    }
    
    @objc func openInMaps() {
        
        let regionDestination: CLLocationDistance = 10000
        let coordinates = location.coordinate
        
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center) ,
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        
        ]
        
        let placeMark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placeMark)
        
        mapItem.name = "User's Location"
        
        mapItem.openInMaps(launchOptions: options)
        
        
    }
    

}
