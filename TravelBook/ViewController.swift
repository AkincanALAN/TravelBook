//
//  ViewController.swift
//  TravelBook
//
//  Created by Akıncan ALAN on 7/19/24.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var chosenLongitude = Double()
    var chosenLatitude = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            // CoreData
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let stringId = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringId)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let titleValue = result.value(forKey: "title") as? String {
                            annotationTitle = titleValue
                            
                            if let subtitleValue = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitleValue
                                
                                if let latitudeValue = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitudeValue
                                    
                                    if let longitudeValue = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitudeValue
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                print("fetch error, ViewController")
            }
            
        } else {
            // The segue was performed by cell. User can add new data.
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[locations.count - 1].coordinate.latitude, longitude: locations[locations.count - 1].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesWhenAdded = true
            pinView?.canShowCallout = true
            pinView?.tintColor = .black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if selectedTitle != "" {
                
                let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
                
                CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                    //closure
                    
                    if let placemark = placemarks {
                        if placemark.count > 0 {
                                          
                            let newPlacemark = MKPlacemark(placemark: placemark[0])
                            let item = MKMapItem(placemark: newPlacemark)
                            item.name = self.annotationTitle
                            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                            item.openInMaps(launchOptions: launchOptions)
                                          
                    }
                }
            }
        }
    }
    
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    
    
    
    @IBAction func saveButton(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}

