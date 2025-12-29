//
//  LocationManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/28/25.
//

import Foundation
internal import CoreLocation
import Combine

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    var manager = CLLocationManager()
    
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    
    func checkLocationAuthorization() {
        
        manager.delegate = self
        manager.startUpdatingLocation()
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
            
        case .restricted:
            print("Location service restricted")
            
        case .denied:
            print("Location service denied")
            
        case .authorizedAlways:
            lastKnownLocation = manager.location?.coordinate
            
        case .authorizedWhenInUse:
            lastKnownLocation = manager.location?.coordinate
            
        @unknown default:
            print("Location service disabled")
        
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
        onAuthorizationChange?(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
}
