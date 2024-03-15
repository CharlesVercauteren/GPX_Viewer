//
//  GpxParser.swift
//  XMLParser
//
//  Created by Charles Vercauteren on 16/01/2024.
//

import Foundation
import CoreLocation
import MapKit

struct WayPoint {
    var loc: CLLocationCoordinate2D
    var name: String
    var desc: String
    
    init(){
        self.loc = CLLocationCoordinate2D()
        self.name = ""
        self.desc = ""
    }
    
    mutating func reset() {
        self = WayPoint()
    }
}

struct TrackPoint {
    var loc: CLLocationCoordinate2D
    var elevation: Double
    var elevationStr: String
    var length: Double
    
    init() {
        self.loc = CLLocationCoordinate2D()
        self.elevation = 0
        self.elevationStr = ""
        self.length = 0
    }
    
    mutating func reset() {
        self = TrackPoint()
    }
}

struct TrackInfo {
    var name: String
    //var length: Double              // Lengte van de track
    //var heightDiff: Double          // Hoogteverschil track
    
    init() {
        self.name = ""
        //self.length = 0
        //self.heightDiff = 0
    }
    
    mutating func reset() {
        self = TrackInfo()
    }
}


class GpxParser: NSObject, XMLParserDelegate {
    var parser: XMLParser?
    var trackInfo = TrackInfo()                     // TrackInfo
    var trackPoints = [TrackPoint]()                // Trackpoints
    var trackPoint = TrackPoint()                   // Array met trackpoints
    var wayPoints = [WayPoint]()                    // Array met Waypoints
    var wayPoint = WayPoint()
    var heightDifferenceOfTrack: Double = 0         // Hoogteverschil van de track
    var trackRegion = MKCoordinateRegion()          // Gebied waarbinnen trakc valt
    

    
    func parse(_ data: Data) -> Bool {
        // Init
        trackPoints.removeAll()
        wayPoints.removeAll()

        // Interpreteer de gpx
        parser = XMLParser(data: data)
        guard parser != nil else { return false }
        parser!.delegate = self
        
        let succes = parser!.parse()
        
        calculateElevationOfTrack()         // Zet de ingelezen string van hoogte om naar een double en plaats in trackPoints array
        calculateLengthOfTrack()            // Berekenen lengte van start tot trackpoints en plaats in trackPoints variabele
        
        return(succes)
    }
    
    // Bepaal de lengte van de track
    private func calculateLengthOfTrack() {
        var lengthOfTrack: CLLocationDistance = 0
        
        guard trackPoints.count >= 2 else { return() }
        
        for i in 1..<trackPoints.count {
            let trackA = trackPoints[i-1]
            let trackB = trackPoints[i]
            
            let locA = CLLocation(latitude: trackA.loc.latitude, longitude: trackA.loc.longitude)
            let locB = CLLocation(latitude: trackB.loc.latitude, longitude: trackB.loc.longitude)
            
            lengthOfTrack += locA.distance(from: locB)
            trackPoints[i].length = lengthOfTrack
        }
        return()
    }
    
    // Bepaal de double waarde van de hoogtes
    private func calculateElevationOfTrack() {
        for i in 0..<trackPoints.count {
            // TODO: is dit de goede manier om de hoogte te bepalen
            let index = trackPoints[i].elevationStr.firstIndex(of: "\n")
            if index != nil {
                trackPoints[i].elevation = Double(trackPoints[i].elevationStr.prefix(upTo: index!))!
            }
            else {
                trackPoints[i].elevation = 0
            }
        }
    }
    
    // Bepaal region waarbinnen alle tracks liggen
    func trackGetRegion() -> MKCoordinateRegion {
        // Extends van de region bepaald door "trackPoints"
        var left = CLLocationCoordinate2D()
        var right = CLLocationCoordinate2D()
        var top = CLLocationCoordinate2D()
        var bottom = CLLocationCoordinate2D()
        // Maak region waarbinnen track valt iets groter
        let xtraRegion = 1.1
        
        left.longitude = Double.infinity
        right.longitude = -Double.infinity
        top.latitude = -Double.infinity; 
        bottom.latitude = Double.infinity;
        
        for track in trackPoints {
            if track.loc.latitude < bottom.latitude { bottom.latitude = track.loc.latitude}
            if track.loc.latitude > top.latitude { top.latitude = track.loc.latitude}
            if track.loc.longitude < left.longitude { left.longitude = track.loc.longitude}
            if track.loc.longitude > right.longitude { right.longitude = track.loc.longitude}
        }
        let center = CLLocationCoordinate2D(latitude: top.latitude-(top.latitude-bottom.latitude)/2, longitude: right.longitude-(right.longitude-left.longitude)/2)
        trackRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: xtraRegion*(top.latitude-bottom.latitude), longitudeDelta: xtraRegion*(right.longitude-left.longitude)))
        return trackRegion
    }
    
    func trackGetRegionWidthMeters() -> CLLocationDistance {
        let leftPoint = MKMapPoint(CLLocationCoordinate2D(latitude: trackRegion.center.latitude, longitude: trackRegion.center.longitude - trackRegion.span.longitudeDelta ))
        let rightPoint = MKMapPoint(CLLocationCoordinate2D(latitude: trackRegion.center.latitude, longitude: trackRegion.center.longitude + trackRegion.span.longitudeDelta))
        return leftPoint.distance(to: rightPoint)
    }
    
    // Track naam opvragen
    func getTrackInfo() -> TrackInfo {
        return(trackInfo)
    }
    
    // Waypoints opvragen
    func getWayPoints() -> [MKPointAnnotation] {
        var markers = [MKPointAnnotation]()
        
        for wp in wayPoints {
            let marker = MKPointAnnotation()
            marker.coordinate = wp.loc
            marker.title = wp.name
            marker.subtitle = wp.desc
            markers.append(marker)
        }
        return(markers)
    }
    
    // Track opvragen
    func getTrackPoints() -> [TrackPoint] {
        return(trackPoints)
    }
    
    // Track lengte opvragen
    func getTotalLengthOfTrack() -> CLLocationDistance {
        guard trackPoints.count != 0 else { return(0)}

        return(trackPoints[trackPoints.count-1].length)
    }
    
    // Track hoogte verschil opvragen
    func getHeigthDiffOfTrack() -> Double {
        var min = Double.infinity
        var max = -Double.infinity
        
        for track in trackPoints {
            if track.elevation > max { max = track.elevation }
            if track.elevation < min { min = track.elevation }
        }
        return(max - min)
    }
    
    // XMLParser delegates
    var wptOn = false
    var element = ""
    var level = ""

    internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        element = elementName
        
        switch elementName {
        case "trk":
            level = "trk"
            trackInfo.reset()
        case "trkpt":
            level = "trkpt"
            trackPoint.reset()
            for a in attributeDict {
                if a.key == "lon" { trackPoint.loc.longitude = Double(a.value)! }
                if a.key == "lat" { trackPoint.loc.latitude = Double(a.value)!  }
            }
        case "wpt":
            level = "wpt"
            //element = "wpt"
            wayPoint.reset()
            for a in attributeDict {
                if a.key == "lon" { trackPoint.loc.longitude = Double(a.value)! }
                if a.key == "lat" { trackPoint.loc.latitude = Double(a.value)!  }
            }
            wayPoint.loc = trackPoint.loc
        default:
            break
        }
    }
    
    internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "trk":
            level = ""
        case "wpt":
            wayPoints.append(wayPoint)
            level = ""
        case "trkpt":
            trackPoints.append(trackPoint)
            level = ""
        default:
            break
        }
    }
    
    internal func parser(_ parser: XMLParser, foundCharacters: String) {
        if level == "trk" {
            if element == "name" { trackInfo.name += foundCharacters }
        }
        if level == "wpt" {
            if element == "name" { wayPoint.name += foundCharacters }
            if element == "desc" { wayPoint.desc += foundCharacters }
        }
        if level == "trkpt" {
            if element == "ele" { trackPoint.elevationStr += foundCharacters }
        }

    }
    
}
