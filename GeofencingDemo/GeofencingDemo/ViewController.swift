//
//  ViewController.swift
//  GeofencingDemo
//
//  Created by MAC on 04/03/24.
//

/*
 Geofencing
 
 Geofencing is a location-based technology that allows you to define virtual boundaries or perimeters around real-world geographical areas. These virtual boundaries can trigger actions when a user enters or exits the defined area.
 
 Here's some key information about geofencing:
 
 Definition: Geofencing is the practice of using GPS or RFID (Radio Frequency Identification) technology to create a virtual boundary around a real-world geographic area. This boundary, often represented as a circle or polygon, can be customized to a specific radius and location.
 Purpose: Geofencing is used for a variety of purposes across different industries, including:
 
 Location-based marketing: Sending targeted notifications or advertisements to users when they enter a specific area, such as a retail store or a tourist attraction.
 Fleet management: Monitoring and tracking vehicles to optimize routes, ensure compliance with regulations, and improve efficiency.
 Asset tracking: Keeping track of valuable assets within defined areas, such as construction sites or warehouses.
 Safety and security: Alerting authorities or individuals when someone enters or exits a restricted area, such as a school campus or a hazardous zone.
 Implementation: Geofencing is typically implemented using GPS technology on mobile devices, such as smartphones and tablets. Developers can use platform-specific APIs, such as Core Location on iOS and Google Play Services on Android, to create geofences and monitor users' locations.
 Geofence Triggers: Geofences can trigger actions when a user enters or exits the defined area. Common triggers include:
 
 Entry event: When a user enters the geofenced area.
 Exit event: When a user exits the geofenced area.
 Dwell event: When a user remains within the geofenced area for a specified period of time.
 Privacy Considerations: Since geofencing involves tracking users' locations, it raises privacy concerns. App developers and businesses must obtain users' consent and adhere to privacy regulations, such as GDPR (General Data Protection Regulation) in the European Union and CCPA (California Consumer Privacy Act) in California.
 Battery Optimization: Continuous monitoring of users' locations can drain device battery. To optimize battery usage, developers can implement techniques such as geofence radius optimization, background location updates, and intelligent scheduling of location-based tasks.
 
 Overall, geofencing is a powerful technology that enables location-based interactions and services, but it requires careful implementation to ensure user privacy and battery efficiency.
 */


import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager?
    var isAppTerminated = false // creating for testing SignificantLocationChanges()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        mapView.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        // trigger to check are we able to get location after killing app
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        
    }
}

// MARK: CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .notDetermined:
            print("When user did not yet determined")
        case .restricted:
            print("Restricted by parental control")
        case .denied:
            print("When user select option Dont't Allow")
        case .authorizedWhenInUse:
            print("When user select option Allow While Using App or Allow Once")
            locationManager?.requestAlwaysAuthorization()
        default:
            locationManager?.allowsBackgroundLocationUpdates = true
            locationManager?.pausesLocationUpdatesAutomatically = false
            configureLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        debugPrint(location.coordinate)
        if isAppTerminated {
            scheduleLocalNotification(message: "App Terminated Still receieving callbacks", needToRepeat: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if isAppTerminated {
            scheduleLocalNotification(message: "App Terminated, getting error", needToRepeat: true)
            
        }
    }
}

// METHODS
extension ViewController {
    
    private func setupGeofencing(location: CLLocationCoordinate2D) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            showAlert(message: "Geofencing is not supported on this device")
            return
        }
        
        guard locationManager?.authorizationStatus == .authorizedAlways else {
            showAlert(message: "App does not have correct location authorization")
            return
        }
        
        startMonitoring(location: location)
    }
    
    private func startMonitoring(location: CLLocationCoordinate2D) {
        let regionCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.336105,
                                                                              longitude: -122.000029)//"37.336105" lon="-122.000029">
        let geofenceRegion: CLCircularRegion = CLCircularRegion(
            center: regionCoordinate,
            radius: 200, // Radius in Meter
            identifier: "N Tantau Ave" // unique identifier
        )
        let circle = MKCircle(center: regionCoordinate, radius: 200)
        mapView.addOverlay(circle)

        // This will create a circular area with taking radius from coordinates you mentioned and notifyOnEntry will call when user enters in that area
        geofenceRegion.notifyOnEntry = true
        
        // notifyOnExit will call when user exits from that area
        geofenceRegion.notifyOnExit = true
        locationManager?.startMonitoringSignificantLocationChanges()
        
        // Start monitoring
        locationManager?.startMonitoring(for: geofenceRegion)
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Information", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }
}


/*
 In some cases error occurs while trying to monitor the region that we have set, region monitoring might fail because the region itself cannot be monitored or because there was a more general failure in configuring the region monitoring service.
 */

extension ViewController {
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard let region = region else {
            print("The region could not be monitored, and the reason for the failure is not known.")
            return
        }
        
        print("There was a failure in monitoring the region with a identifier: \(region.identifier)")
    }
}

//MARK: When user enters and exit from regions
/*
 If the user's device enters the circular region (inside the 200-meter radius from the center), the didEnterRegion delegate method of the location manager will be called.
 If the user's device exits the circular region (moves outside the 200-meter radius from the center), the didExitRegion delegate method of the location manager will be called.
 */

extension ViewController {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print(region)
        guard let manager = manager.location?.coordinate, let _ = region as? CLCircularRegion  else {
            return
        }
        self.createAnnotation(centerLocation: CLLocationCoordinate2D(latitude: manager.latitude,
                                                                     longitude: manager.longitude), name: "started")
        
        self.scheduleLocalNotification(message: "Enters in  your area", needToRepeat: false)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print(region)
        print("didExitRegion called")
        
        guard let manager = manager.location?.coordinate, let _ = region as? CLCircularRegion  else {
            return
        }

        self.createAnnotation(centerLocation: CLLocationCoordinate2D(latitude: manager.latitude,
                                                                     longitude: manager.longitude), name: "end")
        
        self.scheduleLocalNotification(message: "Leaving your area", needToRepeat: false)
        
        
    }
}

extension ViewController {
    func configureLocation() {
        let location = locationManager?.location ?? CLLocation(latitude: 37.3352915,
                                                               longitude: -122.0203281)
        locationManager?.startUpdatingLocation()
        createAnnotation(centerLocation: CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                longitude: location.coordinate.longitude), name: "Intial Location")
        setupGeofencing(location: location.coordinate )
        
    }
    
    func createAnnotation(centerLocation: CLLocationCoordinate2D, name: String) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // You can adjust these values
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLocation.latitude, longitude: centerLocation.longitude), span: span)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: centerLocation.latitude, longitude: centerLocation.longitude)
        annotation.title = name
        mapView.addAnnotation(annotation)
        
        // Set the region on your map view without animation
        UIView.performWithoutAnimation {
            mapView.setRegion(region, animated: false)
        }
    }
    
    func isSameCoordinate(annotation: CLLocationCoordinate2D, regionPoint: CLLocationCoordinate2D) -> Bool {
        if (annotation.latitude == regionPoint.latitude) && annotation.longitude == regionPoint.longitude {
            return true
        }
        return false
    }
}

// MARK: Local notifications
extension ViewController {
    
    // Schedule local notification
    func scheduleLocalNotification(message: String, needToRepeat: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Geofence Notification"
        content.body = message
        content.sound = UNNotificationSound.default
        // You can also set badge and other properties if needed
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: needToRepeat)
        let request = UNNotificationRequest(identifier: "yourNotificationIdentifier", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    @objc func appWillTerminate() {
        // Perform actions specific to this view controller before app termination
        isAppTerminated = true
        locationManager?.startMonitoringSignificantLocationChanges()
        
    }
}
