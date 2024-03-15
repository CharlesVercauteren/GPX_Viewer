//
//  ViewController.swift
//  iGpxViewer
//
//  Created by Charles Vercauteren on 06/02/2024.
//

import UIKit
import MapKit
import CoreLocation

// Globaal:nodig in NavigateViewController
var trackPoints = [TrackPoint]()                        // Trackpoints in gpx
var overlayTrack = MKPolyline()                         // Overlay voor de track


class ViewController: UIViewController {
    
    var appDelegate: AppDelegate?
    
    @IBOutlet var infoTxt: UILabel!
    
    // De map
    @IBOutlet var map: MKMapView!

    // Toon/verberg track/waypoints/trackpoints op de map
    @IBOutlet var trackSwh: UISwitch!
    @IBOutlet var trackSwhLbl: UILabel!
    @IBOutlet var wayPointsSwh: UISwitch!
    @IBOutlet var wayPointsLbl: UILabel!
    @IBOutlet var trackPointsSwh: UISwitch!
    @IBOutlet var trackPointsSwhLbl: UILabel!
    
    // Toon totale lengte en hoogteverschil
    @IBOutlet var lengthOfTrackLbl: UILabel!
    @IBOutlet var heightOfTrackLbl: UILabel!
    
    // Hoogteprofiel in functie van de afstand
    @IBOutlet var mapElevations: ElevationProfile!
    @IBOutlet var heightLbl: UILabel!
        
    // Variabelen
    var gpxParser = GpxParser()                             // Parser object
    var wayPoints = [MKPointAnnotation]()                   // Waypoints in gpx
    
    // Overlays voor track resp. positie in hoogteprofiel
    var overlayHeight = MKCircle()                          // Overlay voor positie hoogte
    var overlayTrackPoints = [TrackPointsCircle]()          // Overlay voor de trackpoints
    var radiusOverlayTrackPoints: CLLocationDistance = 0
    var radiusOverlayCircle: CLLocationDistance = 0

    var selectedPath: URL?                                  // Path naam geselecteerd bestand
    var searchPath: FileManager.SearchPathDirectory = .documentDirectory
    var searchDomain: FileManager.SearchPathDomainMask = .userDomainMask
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localisatie in AppDelegate. Referentie naar map doorsturen naar AppDelegate
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate?.setMap(to: map)
        
        // Map instellen
        map.delegate = self
        map.showsCompass = true     // Om zichtbaar te worden even draaien zodat kaart niet meer naar N wijst.
        map.showsScale = true       // Om zichtbaar te zijn, even zoomen
        map.setUserTrackingMode(.followWithHeading, animated: true)
        map.showsUserLocation = true
        
        // Hoogtefiguur instellen
        mapElevations.delegate = self
        
        // Controleer of de document-map van app aanwezig is, zoniet maak aan.
        // Gpx-n moeten zich in deze map bevinden
        documentMapPresent(self)
    }
        
    @IBAction func fileSelectionBtn(_ sender: Any) {
        // Toon lijst met bestanden in de applicatiemap als dialoog venster
        // Path naam komt binnen via "FileSelectionDelegate". Deze roept de functie openGpx() aan.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fileselectionVC = storyboard.instantiateViewController(identifier: "fileselectionview")                         as FileSelectionViewController
        fileselectionVC.delegate = self
        present(fileselectionVC, animated: true)
    }
    
    func openGpx(_ sender: Any?) {
        var contentStr = ""

        // Init
        trackSwh.isEnabled = false
        trackPointsSwh.isEnabled = false
        wayPointsSwh.isEnabled = false                  // Disable waypoints switch en label if no waypoints
        trackSwhLbl.isEnabled = trackSwh.isEnabled
        trackPointsSwhLbl.isEnabled = trackPointsSwh.isEnabled
        wayPointsLbl.isEnabled = wayPointsSwh.isEnabled
        
        map.removeAnnotations(wayPoints)
        map.removeOverlay(overlayHeight)

        
        // Bestand inlezen
        do { contentStr = try String(contentsOf: selectedPath!) }
        catch let error as NSError { infoTxt.text = "Fout lezen bestand:\n\(error)" }
                        
        let content: Data = contentStr.data(using: .utf8)!
        
        guard gpxParser.parse(content) else {
            infoTxt.text = "Parsing failed"
            return
        }
        
        trackSwh.isEnabled = true
        trackPointsSwh.isEnabled = true
        trackSwhLbl.isEnabled = trackSwh.isEnabled
        trackPointsSwhLbl.isEnabled = trackPointsSwh.isEnabled
        
        // Toon naam track
        infoTxt.text = gpxParser.getTrackInfo().name
        // Track
        trackPoints = gpxParser.getTrackPoints()
        lengthOfTrackLbl.text = String(format: "Afstand: %.2f m", gpxParser.getTotalLengthOfTrack())
        heightOfTrackLbl.text = String(format: "Hoogteverschil: %.2f m", gpxParser.getHeigthDiffOfTrack())
        
        // Waypoints
       // map.removeAnnotations(wayPoints)
        wayPoints = gpxParser.getWayPoints()

        if wayPoints.count > 0 {
            wayPointsSwh.isEnabled = true
            wayPointsLbl.isEnabled = wayPointsSwh.isEnabled
        }
        // Height
        //map.removeOverlay(overlayHeight)
        overlayHeight = MKCircle(center: trackPoints[0].loc, radius: radiusOverlayCircle)
        map.addOverlay(overlayHeight)
        
        // Teken map
        map.region = gpxParser.trackGetRegion()
        drawTrack()
        drawWayPoints()
        drawElevations()
        }
    

    
    private func drawTrack() {
        map.removeOverlay(overlayTrack)
        if trackSwh.isOn {
            var locations = [CLLocationCoordinate2D]()
            // Track
            for trackPoint in trackPoints {
                locations.append(trackPoint.loc)
            }
            overlayTrack = MKPolyline(coordinates: locations, count: locations.count)
            map.addOverlay(overlayTrack)
        }
    }
    
    private func drawElevations() {
        mapElevations.setNeedsDisplay()
    }
    
    private func drawTrackPoints() {
        map.removeOverlays(overlayTrackPoints)
        overlayTrackPoints.removeAll()
        if trackPointsSwh.isOn {
            for track in trackPoints {
                overlayTrackPoints.append(TrackPointsCircle(center: track.loc, radius: radiusOverlayTrackPoints))
            }
            map.addOverlays(overlayTrackPoints)
        }
    }
    
    private func drawWayPoints() {
        map.removeAnnotations(wayPoints)
        // TODO: .on is vervangen door .selected
        if wayPointsSwh.isOn {
            map.addAnnotations(wayPoints)
        }
    }
    
    private func drawElevationPosition(for location: CLLocationCoordinate2D) {
        // Teken op de track een cirkel om aan te geven waar de hoogte uit het
        // hoogtevenster optreedt.
        map.removeOverlay(overlayHeight)
        overlayHeight = MKCircle(center: location, radius: radiusOverlayCircle)
        map.addOverlay(overlayHeight)
    }
    
    @IBAction func centerUserBtnChanged(_ sender: Any) {
        //guard userLocation != nil else { return }
        guard appDelegate?.getUserLocation() != nil else { return }
        map.setCenter((appDelegate?.getUserLocation()!.coordinate)!, animated: true)
        //map.setCenter((userLocation?.location!.coordinate)!, animated: true)
    }

    @IBAction func trackSwhChanged(_ sender: Any) {
        drawTrack()
    }
    
    @IBAction func trackPointsSwhChanged(_ sender: Any) {
        drawTrackPoints()
    }
    
    @IBAction func wayPointsSwhChanged(_ sender: Any) {
        drawWayPoints()
    }
    
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        // We slepen cursor (vinger :-))  in hoogtevenster
        // Teken vertikale lijn in hoogte venster
        mapElevations.setCursorPostion(to: sender.location(in: mapElevations))
    }
    
    private func documentMapPresent(_ sender: Any) {
        // Lokaal bestand op iPad
        var dirs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let tekst = "Gpx viewer document map."

        if dirs.count != 0 {
            let path = dirs[0].appendingPathComponent("Test.txt")
            
            do {
                try tekst.data(using: .ascii)!.write(to: path)
                //infoTxt.text = "Document map aangemaakt."
            }
            catch {
                infoTxt.text = "Error: bestand niet weggeschreven."
            }
        }
        else { print("Dir not found")}
    }
    
    @IBAction func navigateBtnPushed(_ sender: Any) {
        performSegue(withIdentifier: "toNavigate", sender: self)
    }
}

extension ViewController: MKMapViewDelegate {
        
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
        switch overlay {
        case is MKPolyline:
            // Track
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 2
            //renderer.lineDashPattern = [10,5,5,5]
            renderer.strokeColor = UIColor.red
            //polyline.fillColor = NSColor.yellow
            return(renderer)
        case is TrackPointsCircle:
            // Trackpoints
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.red
            renderer.fillColor = renderer.strokeColor
            return renderer
        case is MKCircle:
            // Elevation op track
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.blue
            renderer.fillColor = renderer.strokeColor
            return renderer
        default:
            print("Error mapView")
            let renderer = MKOverlayRenderer(overlay: MKCircle())
            return(renderer)
        }
    }
        
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let leftPoint = MKMapPoint(CLLocationCoordinate2D(latitude: map.region.center.latitude, longitude: map.region.center.longitude - map.region.span.longitudeDelta ))
        let rightPoint = MKMapPoint(CLLocationCoordinate2D(latitude: map.region.center.latitude, longitude: map.region.center.longitude + map.region.span.longitudeDelta))
        // Om te vermijden dat de hoogtecirkel (diameter = afstand links tot rechts / 150) veranderd bij het vergroten van het venster houden
        // we rekening met de breedte van het venster. 500 is default breedte (ontwerp) van het venster.
        radiusOverlayCircle = (leftPoint.distance(to: rightPoint)/150) // * 500/Double((heightProfile.window?.contentView?.bounds.width)!)
        radiusOverlayTrackPoints = radiusOverlayCircle
    }
}

extension ViewController: ElevationProfileDelegate {
        
    func distanceChanged(_ distance: Double, _ height: Double) {
        // Zoek locatie van afstand
        var track = TrackPoint()
        for t in trackPoints {
            if distance <= t.length { track = t; break}
        }
        heightLbl.text = String(format: "Afstand: %.2f m - Hoogte: %.2f m", distance, height)
        drawElevationPosition(for: track.loc)
    }
}

extension ViewController: FileSelectionDelegate {
    
    func pathSelected(is path: URL) {
        selectedPath = path
        openGpx(self)
    }
}



