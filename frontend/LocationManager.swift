//
//  LocationManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/28/25.
//

internal import CoreLocation
import Combine

class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {

    @Published var mostRecentLocation: CLLocation?
    let locationManager: CLLocationManager
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        locationManager.delegate = self
    }

    // MARK: - LocationService

    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways,
             .authorizedWhenInUse,
             .restricted,
             .denied:
            return
        @unknown default:
            break
        }
    }
    
    func requestCurrentLocation() {
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined,
             .authorizedAlways,
             .authorizedWhenInUse,
             .restricted,
             .denied:
            onAuthorizationChange?(manager.authorizationStatus)
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations[locations.count-1] as CLLocation
        if (location.horizontalAccuracy > 0) {
            DispatchQueue.main.async {
                self.mostRecentLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("Error obtaining location: \(error.localizedDescription)")
    }
}
