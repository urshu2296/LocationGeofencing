//
//  ViewController.swift
//  GeofencingDemo
//
//  Created by MAC on 04/03/24.
//



import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager?
    var isAppTerminated = false // creating for testing SignificantLocationChanges()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        mapView.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
    }
    
    @IBAction func addRegion(sender: Any) {
        guard let longPress = sender as? UILongPressGestureRecognizer else { return }
        let touchLocation = longPress.location(in: mapView)
        let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        let geofenceRegion = CLCircularRegion(center: coordinate, radius: 200, identifier: "geofence")
        mapView.removeOverlays(mapView.overlays)
        geofenceRegion.notifyOnEntry = true
        
        // notifyOnExit will call when user exits from that area
        geofenceRegion.notifyOnExit = true
        locationManager?.startMonitoringSignificantLocationChanges()
        locationManager?.startMonitoring(for: geofenceRegion)
        let circle = MKCircle(center: coordinate, radius: geofenceRegion.radius)
        mapView.addOverlay(circle)

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
            locationManager?.startUpdatingLocation()
            locationManager?.allowsBackgroundLocationUpdates = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if isAppTerminated {
            scheduleLocalNotification(message: "App Terminated, getting error", needToRepeat: true)
            
        }
    }
}

// METHODS
extension ViewController {
    
    
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
        self.scheduleLocalNotification(message: "We entered in your location", needToRepeat: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print(region)
        self.scheduleLocalNotification(message: "Bubye we are leaving your area!!", needToRepeat: false)
    }
}

extension ViewController {
    
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
        let request = UNNotificationRequest(identifier: "my_notification", content: content, trigger: trigger)
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

//MARK: MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.strokeColor = .red
        circleRenderer.fillColor = .red
        circleRenderer.alpha = 0.5
        return circleRenderer
    }
}
