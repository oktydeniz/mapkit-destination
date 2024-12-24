//
//  ViewController.swift
//  my-locations
//
//  Created by oktay on 24.12.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapKitView: MKMapView!
    let locationManager = CLLocationManager()
    let regionAreaSize: Double = 15000
    @IBOutlet weak var screenLabel: UILabel!
    var formerLocation : CLLocation?
    var directions: [MKDirections] = []
    @IBOutlet weak var goBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        controlLocationService()
        goBtn.layer.cornerRadius = 18
        
    }

    func controlLocationService() {
        if CLLocationManager.locationServicesEnabled() {
            setLocationManager()
            permissionCheck()
        } else {
            print("Location services are disabled.")
        }
    }
    
    func setLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func permissionCheck() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    @IBAction func goAction(_ sender: Any) {
        createDestination()
    }
    
    func createDestination() {
        guard let startCoord = locationManager.location?.coordinate else {return}
        
        let req = createReq(start: startCoord)
        let directions = MKDirections(request: req)
        clear(newDest: directions)
        directions.calculate {(response, error) in
            
            guard let res = response else {return}
            for i in res.routes {
                self.mapKitView.addOverlay(i.polyline)
                self.mapKitView.setVisibleMapRect(i.polyline.boundingMapRect, animated: true)
                
            }
            
        }
    }
    
    func createReq(start:CLLocationCoordinate2D) -> MKDirections.Request {
        let dest = centerCoordinate(mapView: mapKitView).coordinate
        
        let startPoint = MKPlacemark(coordinate: start)
        
        let destinationPont = MKPlacemark(coordinate: dest)
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startPoint)
        request.destination = MKMapItem(placemark: destinationPont)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    func clear(newDest: MKDirections){
        mapKitView.removeOverlays(mapKitView.overlays)
        self.directions.append(newDest)
        
        let _ = self.directions.map { $0.cancel()}
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("User's location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionAreaSize, longitudinalMeters: regionAreaSize)
        mapKitView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("Location authorized always.")
            startMapLocation()
        case .authorizedWhenInUse:
            print("Location authorized when in use.")
            startMapLocation()
        case .denied:
            print("Location access denied.")
        case .notDetermined:
            print("Location permission not determined.")
        case .restricted:
            print("Location access restricted.")
        @unknown default:
            print("A new case was added that is not handled.")
        }
    }
    
    func startMapLocation(){
        locationManager.startUpdatingLocation()
        mapKitView.showsUserLocation = true
        mapKitView.userTrackingMode = .follow
        focusLocation()
        formerLocation = centerCoordinate(mapView: mapKitView)
    }
    
    func focusLocation(){
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionAreaSize, longitudinalMeters: regionAreaSize)
            mapKitView.setRegion(region, animated: true)
        }
    }
    
    func centerCoordinate(mapView: MKMapView) -> CLLocation {
        let latitute = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitute, longitude: longitude)
    }
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = centerCoordinate(mapView: mapKitView)
        guard let prevLoc = self.formerLocation else {return}
        if center.distance(from: prevLoc) < 50 {return}
        self.formerLocation = center
        
        let geoCoord = CLGeocoder()
        geoCoord.cancelGeocode()
        
        geoCoord.reverseGeocodeLocation(center) { (placeMark, error) in
            if let _ = error {
                return
            }
            guard let place = placeMark?.first else {
                return
            }
            
            let streetNumber = place.subThoroughfare ?? "Not Found!"
            let streetName = place.thoroughfare ?? "Not Found!"
            let countryName = place.country ?? "Not Found!"
            let district = place.administrativeArea ?? "Not Found!"
            let cityName = place.locality ?? "Not Found!"
            
            DispatchQueue.main.async {
                self.screenLabel.text = "\(cityName) / \(district) / \(countryName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineCap = .square
        renderer.lineWidth = 7
        return renderer
    }
}
