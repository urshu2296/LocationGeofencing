Significant Location Change Monitoring:

- Used CLLocationManager to monitor significant location changes by calling startMonitoringSignificantLocationChanges() in the viewDidLoad() method of your ViewController.
This allows your app to receive location updates even when it's in the background or terminated.

Geofencing Setup:
Added a circular geofence area around a specific location (e.g., Apple Park) by creating a CLCircularRegion object with a center coordinate, radius, and identifier.
This geofence region is created in the startMonitoring(location:) method of your ViewController and is set to notify on entry and exit (notifyOnEntry and notifyOnExit).
The geofence monitoring is started with startMonitoring(for:) method of CLLocationManager.

Handling Geofence Events:
When the user enters or exits the geofence area, the corresponding delegate methods (locationManager(_:didEnterRegion:) and locationManager(_:didExitRegion:)) of CLLocationManagerDelegate are called.
Inside these methods, created annotations on the map to indicate the user's entry or exit from the geofence area

Handling App Termination: (verifying significant location)
-  track the app termination state using a boolean variable (isAppTerminated) and set it to true in the applicationWillTerminate method of VC.
- Used this approach of throwing a local notification when the app is terminated and then checking if the app is in a terminated state in the didUpdateLocations delegate
method using boolean variable to throw local notification is a valid way to verify if significant location changes are working correctly in killed state.

