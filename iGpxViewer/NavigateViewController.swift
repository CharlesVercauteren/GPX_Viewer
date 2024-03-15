//
//  NavigateViewController.swift
//  iGpxViewer
//
//  Created by Charles Vercauteren on 28/02/2024.
//

import UIKit
import MapKit

class NavigateViewController: UIViewController {

    @IBOutlet var navMap: MKMapView!
    @IBOutlet var centerBtn: UISwitch!
    @IBOutlet var sateliteSwh: UISwitch!
    
    var userLocation: MKUserLocation?
    var appDelegate: AppDelegate?

    var mapStandardConfig = MKStandardMapConfiguration()
    var mapHybridConfig = MKHybridMapConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate?.setNavigationMap(to: navMap)
        
        navMap.delegate = self
        navMap.preferredConfiguration = mapStandardConfig
        // Om zichtbaar te worden even draaien zodat kaart niet meer naar N wijst.
        navMap.showsCompass = true
        // Om zichtbaar te zijn, even zoomen
        navMap.showsScale = true

        navMap.setUserTrackingMode(.followWithHeading, animated: true)
        navMap.showsUserLocation = true
        
        navMap.removeOverlay(overlayTrack)
        var locations = [CLLocationCoordinate2D]()
        // Track
        for trackPoint in trackPoints {
            locations.append(trackPoint.loc)
        }
        overlayTrack = MKPolyline(coordinates: locations, count: locations.count)
        navMap.addOverlay(overlayTrack)
        
    }
    
    private func drawTrack() {
        navMap.removeOverlay(overlayTrack)
        
        var locations = [CLLocationCoordinate2D]()
        // Track
        for trackPoint in trackPoints {
            locations.append(trackPoint.loc)
        }
        overlayTrack = MKPolyline(coordinates: locations, count: locations.count)
        navMap.addOverlay(overlayTrack)
    }

    @IBAction func centerBtnChanged(_ sender: Any) {
        appDelegate!.centerNavMap = centerBtn.isOn
    }
    
    @IBAction func sateliteSwhChanged(_ sender: Any) {
        if sateliteSwh.isOn {
            navMap.preferredConfiguration = mapHybridConfig
        }
        else {
            navMap.preferredConfiguration = mapStandardConfig
        }
    }
}

extension NavigateViewController: MKMapViewDelegate {
        
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
        switch overlay {
        case is MKPolyline:
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 2
            //renderer.lineDashPattern = [10,5,5,5]
            renderer.strokeColor = UIColor.red
            //polyline.fillColor = NSColor.yellow
            return(renderer)
        case is TrackPointsCircle:
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.red
            renderer.fillColor = renderer.strokeColor
            return renderer
        case is MKCircle:
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.blue
            return renderer
        default:
            print("Error mapView")
            let renderer = MKOverlayRenderer(overlay: MKCircle())
            return(renderer)
        }
    }
}
