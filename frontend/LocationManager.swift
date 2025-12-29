//
//  LocationManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/28/25.
//

internal import CoreLocation
import Combine

class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {

    let locationManager: CLLocationManager
    private var pendingAuthorizationCompletion: ((Bool) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
    }

    // MARK: - LocationService

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways,
             .authorizedWhenInUse,
             .restricted,
             .denied:
            print("Unauthorized")
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            #if os(iOS)
            locationManager.startMonitoringVisits()
            #endif
            onAuthorizationChange?(manager.authorizationStatus)
        case .notDetermined,
             .authorizedWhenInUse,
             .restricted,
             .denied:
            onAuthorizationChange?(manager.authorizationStatus)
        @unknown default:
            break
        }
    }

    #if os(iOS)
    func locationManager(_ manager: CLLocationManager,
                         didVisit visit: CLVisit) {
        print(visit.arrivalDate, visit.departureDate, visit.coordinate)
    }
    #endif
}
