//
//  iXYProfile.swift
//  iGpxViewer
//
//  Created by Charles Vercauteren on 06/02/2024.
//

import UIKit

protocol ElevationProfileDelegate {
    func distanceChanged(_ distance: Double, _ height: Double)
}

class ElevationProfile: UIView {
    
    //var xMin: Double = Double.infinity      // Extremen afstanden en hoogten, minimum afstand is eigenlijk altijd 0
    var xMax: Double = -Double.infinity
    var yMin: Double = Double.infinity
    var yMax: Double = -Double.infinity
    var xScale: Double = 0
    var yScale: Double = 0
    var cursorX: Double = 0                  // X-coördinaat van muis in venster, gebruikt voor tekenen lijn
        
    var delegate: ElevationProfileDelegate?
        
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)

        let gc = UIGraphicsGetCurrentContext()!
            
        // Kader en achtergrond
        gc.setStrokeColor(UIColor.gray.cgColor)
        gc.setFillColor(UIColor.white.cgColor)
        gc.addRect(bounds)
        gc.drawPath(using: CGPathDrawingMode.fillStroke)
            
        // Data uitzetten
        mapData()
        
        guard trackPoints.count != 0 else { return }
        gc.setStrokeColor(UIColor.blue.cgColor)
        for i in 0..<trackPoints.count-1 {
            gc.move(to: CGPoint(x: xScale*trackPoints[i].length, y: bounds.height - yScale*(trackPoints[i].elevation - yMin)))
            gc.addLine(to: CGPoint(x: xScale*trackPoints[i+1].length, y: bounds.height - yScale*(trackPoints[i].elevation - yMin)))
            gc.addLine(to: CGPoint(x: xScale*trackPoints[i+1].length, y: bounds.height - yScale*(trackPoints[i+1].elevation - yMin)))
        }
        gc.drawPath(using: .stroke)
            
        // Muislijn
        gc.setStrokeColor(UIColor.red.cgColor)
        gc.move(to: CGPoint(x: cursorX, y: 0))
        gc.addLine(to: CGPoint(x: cursorX, y: bounds.height))
        gc.drawPath(using: .stroke)
    }
    
    func setCursorPostion(to cursorloc: CGPoint) {
        cursorX = cursorloc.x
        if cursorX < 0 { cursorX = 0 }
        if cursorX > bounds.width { cursorX = bounds.width}
        let dist = cursorX/xScale
        
        let height = findElevation(for: dist)
        delegate?.distanceChanged(dist, height)
        setNeedsDisplay()
    }
    
    private func mapData() {
        // Minima en maxima bepalen
        // xMin is altijd 0
        xMax = -Double.infinity
        yMin = Double.infinity
        yMax = -Double.infinity
        for track in trackPoints {
            xMax = Double.maximum(xMax, track.length)
            yMin = Double.minimum(yMin, track.elevation)
            yMax = Double.maximum(yMax, track.elevation)
        }
        // Schaal bepalen
        xScale = bounds.width/xMax
        yScale = bounds.height/(yMax - yMin)
        // Schaal bepalen
        xScale = bounds.width/xMax  //(xMax - xMin)
        if yMax == yMin {
            yScale = 1
        }
        else {
            yScale = bounds.height/(yMax - yMin)
        }
    }
    
    private func findElevation(for dist: Double) -> Double {
        var elevation: Double = 0
        
        guard trackPoints.count != 0 else { return 0 }
        for i in 1..<trackPoints.count{
            elevation = trackPoints[i-1].elevation
            if dist < trackPoints[i].length { break }
        }
        return elevation
    }
}
