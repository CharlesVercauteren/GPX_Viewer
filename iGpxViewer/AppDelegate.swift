//
//  AppDelegate.swift
//  iGpxViewer
//
//  Created by Charles Vercauteren on 06/02/2024.
//

import UIKit
import MapKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var locManager = CLLocationManager()
    //var viewController: ViewController?
    //var navigateController: NavigateViewController?
    var map: MKMapView?
    var navMap: MKMapView?
    var centerNavMap = false
    var userLocation: CLLocation?
    
    func setMap(to map: MKMapView) {
        self.map = map
    }
    
    func setNavigationMap(to map: MKMapView) {
        self.navMap = map
    }
    
    func getUserLocation() -> CLLocation? {
        return userLocation
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Zorg dat in info.plist de key "Privacy-Localisation when in use usage description" aanwezig is.
        locManager.requestWhenInUseAuthorization()
        locManager.delegate = self
        locManager.startUpdatingHeading()
        locManager.startUpdatingLocation()
        
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let windowScenes = UIApplication.shared.connectedScenes
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            //enableLocationFeatures()
            //print("Location service available")
            break
            
        case .restricted, .denied:  // Location services currently unavailable.
            //disableLocationFeatures()
            //print("Location service not available")
            break
            
        case .notDetermined:        // Authorization not determined yet.
           manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if map != nil {
            map!.camera.heading = newHeading.magneticHeading
        }
        if navMap != nil {
            navMap!.camera.heading = newHeading.magneticHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Laatste van array bevat laatst gemeten lokatie.
        guard locations.count != 0 else { return }
        userLocation = locations[locations.count-1]
        if userLocation != nil && navMap != nil {
            if centerNavMap {
                navMap!.setCenter(userLocation!.coordinate, animated: true)
            }
        }
    }
    
}

