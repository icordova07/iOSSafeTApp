//
//  ViewController.swift
//  project493
//
//  Created by Isis Cordova on 1/13/19.
//  Copyright © 2019 SeniorDesign_17. All rights reserved.
//

import UIKit;
import AWSMobileClient;
import AWSCore
import CoreLocation;
import MessageUI;
import CoreTelephony;
import Foundation;
import MapKit;
import AWSDynamoDB;



class ViewController:  UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var menuView: UIView!
    var menuShowing = false
    let locationManager:CLLocationManager = CLLocationManager()
    let regionInMeters: Double = 100
    var userType = "Driver"
    var current_latitude = ""
    var current_longitude = ""
    var current_timestamp = ""
    var current_Building = "Unknown"
    var current_emergency = "Safe"
    var collisionFlag = 0
    var emergencyFlag = 0
    var eventFlag = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Initializes the table being used in Amazon DynomoDB
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .USEast1,
            identityPoolId: "us-east-1:e58ca19b-4a2f-4541-b8b6-5dfbf79191f1"
        )
        
        let serviceConfiguration = AWSServiceConfiguration(
            region: .USEast1,
            credentialsProvider: credentialProvider
        )
        
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration
        
        // Map Setup on Load
        mapView.showsUserLocation = false
        menuView.layer.shadowOpacity = 1
        menuView.layer.shadowRadius = 6
        
        //Reset the active button and all UI to Gray color (inactive state_=)
        active_button.backgroundColor = UIColor.gray
        self.view.backgroundColor = UIColor(red:0.28, green:0.28, blue:0.28, alpha:1.0) //gray background
        navigationController?.navigationBar.barTintColor = UIColor(red:0.28, green:0.28, blue:0.28, alpha:1.0) //change navigation bar
        active_button.setTitle("SafeT: OFF", for: .normal)
        active_button.setTitleColor(UIColor.lightGray, for: .normal)
        active_button.layer.cornerRadius = active_button.frame.height/2
        
        //Initialize user login credentials
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            if let userState = userState {
                print("UserState: \(userState.rawValue)")
            } else if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
        initializeAWSMobileClient() // Initialize the AWSMobileClient
     }
    
    
/* Location Management*/
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        /*Clear all other past annotations*/
        mapView.showsUserLocation = true
        menuView.layer.shadowOpacity = 1
        menuView.layer.shadowRadius = 6
        /*Clear all other past annotations*/
        mapView.removeAnnotations(mapView.annotations)
        
        let test = 0
        let filename = "location.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        let newgps = "0"
        for currentLocation in locations{
            /*//Pin Configuration
            var pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
            var objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Me"
            self.mapView.addAnnotation(objectAnnotation)*/
            
            let textgps = "\(index):\(currentLocation)"
            let stringtimestamp = "\(currentLocation.timestamp)"
            current_timestamp = stringtimestamp
            let stringlatitude = "\(currentLocation.coordinate.latitude)"
            current_latitude = stringlatitude
            let stringlongitude = "\(currentLocation.coordinate.longitude)"
            current_longitude = stringlongitude
            

            if test == 0 {
                /*Functions that need to be run everytime location is updated*/
                //centerViewOnUserLocation() //Adds users pin on the map
                findBuilding()
                /*Emergency Check*/
                let current_user = AWSMobileClient.sharedInstance().username
                emergencyCheck(user: current_user ?? "icordova")
                /*Collision Checks*/
                collisionCheck(user: "icordova")
                collisionCheck(user: "kevinv")
                collisionCheck(user: "alim")
                collisionCheck(user: "nreyes3")
                collisionCheck(user: "dbell")
                collisionCheck(user: "lrich")
                //pinNearbyUsers(user: "kevinv")
                /*Social Event Checks*/
                //eventCheckDB(Building: self.current_Building)
                eventCheck(Building: self.current_Building)
                databaseFunction() //at the END send info to the database
                let gps = "1"
                let textgps = "\(index):\(currentLocation)"
                let location = gps + textgps + newgps
                do {
                    try location.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Failed to create file")
                    print("\(error)")
                }
                print(path ?? "not found")
                
            }
            let newgps = textgps
            let test = 1
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
/*Clear all Location Data*/
    func cleanLocationData(){
        
        active_button.backgroundColor = UIColor.gray //disabled button color
        active_button.setTitleColor(UIColor.lightGray, for: .normal) //disabled button letter color
        active_button.setTitle("SafeT: OFF", for: .normal)
        active_button.layer.shadowOpacity=0.0
        scSegment.selectedSegmentIndex = -1
        mapView.showsUserLocation = false
        self.view.backgroundColor = UIColor(red:0.28, green:0.28, blue:0.28, alpha:1.0) //gray background
        navigationController?.navigationBar.barTintColor = UIColor(red:0.28, green:0.28, blue:0.28, alpha:1.0) //change navigation bar
        locationManager.stopUpdatingLocation()
    }
    
/*Initialize Location Data*/
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
/*Center map Location Data (NOT USED)*/
    func centerViewOnUserLocation() {

        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
            
            var latDelta:CLLocationDegrees = 0.01
            
            var longDelta:CLLocationDegrees = 0.01
            
            var theSpan:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            var pointLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            
            var _:MKCoordinateRegion = MKCoordinateRegion(center: pointLocation, span: theSpan)
            mapView.setRegion(region, animated: true)
            
            var pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            var objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Me"
            self.mapView.addAnnotation(objectAnnotation)
        }
        
    }
    
    func pinNearbyUsers(user: String){
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId" : user, //The value you're trying to match
        ]
        dynamoDbObjectMapper.query(SafeTTesting2.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if(output != nil){
                print("Got Response")
                for item in (output?.items)! {
                    if (item.value(forKey: "_Longitude") != nil) { //Check if each user has a Longitude value
                        if let existing_longitude = item.value(forKey: "_Longitude") as? String { //Converts output to string for comparison
                            if existing_longitude != "0"{
                                //Pin Configuration
                                if let existing_latitude = item.value(forKey: "_Latitude") as? String { //Check if each user has a Latitude value
                                    if existing_latitude != "0"{
                                        let double_long = existing_longitude as? Double
                                        print("Double Longitude: \(double_long)")
                                        let double_lat = existing_latitude as? Double
                                        let pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(double_lat ?? 0.0, double_long ?? 0.0)
                                        let objectAnnotation = MKPointAnnotation()
                                        objectAnnotation.coordinate = pinLocation
                                        objectAnnotation.title = user
                                        self.mapView.addAnnotation(objectAnnotation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
         
    }
    

    func checkLocationAuthorization() {
        //Verify whether a user gave us permissions to pull location data
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: //only when in us
            //mapView.showsUserLocation = true //places the pin on the map
            //centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            let alertController3 = UIAlertController(title: "Whoops!", message: "In order to locate you, you need to turn on Location Services", preferredStyle: UIAlertController.Style.alert)
            alertController3.addAction(UIAlertAction(title: "Back", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController3, animated: true, completion: nil)
            cleanLocationData()
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            //mapView.showsUserLocation = true //places the pin on the map
            //centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        }
    }

    func checkLocationServices() {
       
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager() //Checks to see if we can pull location
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
            let alertController2 = UIAlertController(title: "Whoops!", message: "In order to locate you, you need to turn on Location Services", preferredStyle: UIAlertController.Style.alert)
            alertController2.addAction(UIAlertAction(title: "Back", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController2, animated: true, completion: nil)
            cleanLocationData()
        }
    }

    
/* UI Functions */
    func activeButton_UI(){
        active_button.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        active_button.setTitle("SafeT: ON", for: .normal)
        active_button.setTitleColor(UIColor.white, for: .normal)
        self.view.backgroundColor = UIColor(red:0.90, green:0.49, blue:0.13, alpha:1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red:0.90, green:0.49, blue:0.13, alpha:1.0)
    }
    
    @IBOutlet weak var scSegment: UISegmentedControl!
    @IBAction func typeOfCommuter(_ sender: UISegmentedControl) {
        let getIndex = scSegment.selectedSegmentIndex
        switch (getIndex) {
        case 0:
            userType = "Driver"
            if active_button.backgroundColor != UIColor.gray {databaseFunction()}
            //update the database (ONLY WHEN BUTTON IS GREEN AND ACTIVE)
        case 1:
            userType = "Cyclist"
            if active_button.backgroundColor != UIColor.gray {databaseFunction()}
        case 2:
            userType = "Pedestrian"
            if active_button.backgroundColor != UIColor.gray {databaseFunction()}
        default:
            userType = "Driver"
            if active_button.backgroundColor != UIColor.gray {databaseFunction()}
        }
    }
    
/*UI Button changes as well as fucntionality*/
    @IBOutlet weak var active_button: UIButton!
    @IBAction func activeButtonToggle(_ sender: AnyObject) {
        if active_button.backgroundColor == UIColor.gray {
            //check to see if user has selected a type of commuter
            if scSegment.selectedSegmentIndex == -1{ //Prompt an error if the user hasn't selected one
                let alertController = UIAlertController(title: "Whoops!", message: "In order to continue, please select your method of transportation.", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "Back", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                
            }
            else{ //Changes the button color if the user has selected a user type
                activeButton_UI()
                checkLocationServices()
                
                //This function allows for the application to begin pulling GPS data
                locationManager.delegate = self
                locationManager.requestAlwaysAuthorization() //Authorization command
                locationManager.startUpdatingLocation()
                locationManager.distanceFilter = 1 //Updates locations every meter (this needs to change depending on the user type)
                
            }
            
        }
        else if active_button.backgroundColor ==  UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0){
            //Changes the button color UX
            cleanLocationData()
            databaseClearFunction()
            /*Reset all FLAGS*/
            collisionFlag = 0
            emergencyFlag = 0
            eventFlag = 0
        }
    }
/*Option Button Functionality*/
    @IBOutlet weak var leadConstraint: NSLayoutConstraint! //side menu sliding
    @IBAction func optionsButton(_ sender: Any) {
        if (menuShowing){
            leadConstraint.constant = -160
            UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()
            })
        }else{
            leadConstraint.constant = 0
            UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()
            })
        }
        menuShowing = !menuShowing
    }

/*Database Scan for Potential Collisions (WORKS)*/
    
    func collisionCheck(user: String){
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId" : user, //The value you're trying to match
        ]
        dynamoDbObjectMapper.query(SafeTTesting2.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if(output != nil){
                print("Got Response")
                for item in (output?.items)! { //Loops through all matches
                    if (self.collisionFlag == 0){
                        if (item.value(forKey: "_Latitude") != nil) { //Check if each user has a Latitude value
                            if let existing_latitude = item.value(forKey: "_Latitude") as? String { //Converts output to string for comparison
                                if existing_latitude != "0"{ //checks to make sure user is ACTIVE
                                    let index_lat = existing_latitude.index(existing_latitude.startIndex, offsetBy: 7) //This creates a substring of the testing database users' latitude
                                    let mySubstring_lat = existing_latitude.prefix(upTo: index_lat)
                                    let index_lat2 = self.current_latitude.index(self.current_latitude.startIndex, offsetBy: 7)//This creates a substring of the current users' latitude
                                    let mySubstring_lat2 = self.current_latitude.prefix(upTo: index_lat2)
                                    //print(existing_latitude)
                                    //print("My SubString of User")
                                    //print(mySubstring_lat2)
                                    //print("My SubString of DB")
                                    //print(mySubstring_lat)
                                    if (mySubstring_lat == mySubstring_lat2){ //Checks to see if found latitude matches user latitude
                                        if (AWSMobileClient.sharedInstance().username != user){ //This checks to see if the user match is its own lat
                                            if (item.value(forKey: "_Type") != nil) { //This checks if a user is Active
                                                if let existing_Active = item.value(forKey: "_Type") as? String {
                                                    if (existing_Active != "Inactive"){ //Actual check if active
                                                        print("found an active match at:")
                                                        print(existing_latitude)
                                                        print(user)
                                                        if (item.value(forKey: "_Type") != nil) {
                                                            if let existing_Type = item.value(forKey: "_Type") as? String {
                                                                if (existing_Type == "Pedestrian"){ //This checks to see if the found user is a Ped
                                                                    if (self.userType == "Driver"){ //This checks to see if the user is a Car (since cars are the only user receiving alerts)
                                                                        self.collisionFlag = 1
                                                                        let alertController = UIAlertController(title: "CAUTION!", message: "Please be careful as our systems indicate there is a nearby pedestrian.", preferredStyle: UIAlertController.Style.alert)
                                                                        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                                                                        self.present(alertController, animated: true, completion: nil)
                                                                        print("found an active pedestrian match at:\(existing_latitude) with \(user)") }
                                                                    
                                                                }
                                                                else if (existing_Type == "Cyclist"){ //This checks to see if the found user is a Ped
                                                                    if (self.userType == "Driver"){ //This checks to see if the user is a Car (since cars are the only user receiving alerts)
                                                                        self.collisionFlag = 1
                                                                        let alertController = UIAlertController(title: "CAUTION!", message: "Please be careful as our systems indicate there is a nearby cyclist.", preferredStyle: UIAlertController.Style.alert)
                                                                        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                                                                        self.present(alertController, animated: true, completion: nil)
                                                                        print("found an active cyclist match at:\(existing_latitude) with \(user)") }}}}
                                                    }
                                                    else{
                                                        print("found an inactive match at:")
                                                        print(existing_latitude)
                                                        print(user)}}}
                                        }
                                        else{
                                            print("Matched itself")}}}
                            }}
                    }//Close if collision flag statement LATITUDE
                    if (self.collisionFlag == 0){
                        if (item.value(forKey: "_Longitude") != nil) { //Check if each user has a Longitude value
                            if let existing_longitude = item.value(forKey: "_Longitude") as? String { //Converts output to string for comparison
                                if existing_longitude != "0"{
                                    let index_lon = existing_longitude.index(existing_longitude.startIndex, offsetBy: 8) //This creates a substring of the testing database users' longitude
                                    let mySubstring_lon = existing_longitude.prefix(upTo: index_lon)
                                    let index_lon2 = self.current_longitude.index(self.current_longitude.startIndex, offsetBy: 8)//This creates a substring of the current users' longitude
                                    let mySubstring_lon2 = self.current_longitude.prefix(upTo: index_lon2)
                                    if (mySubstring_lon == mySubstring_lon2){ //Checks to see if found DB latitude matches current user latitude
                                        if (AWSMobileClient.sharedInstance().username != user){ //This checks to see if the user match is its own lat
                                            if (item.value(forKey: "_Type") != nil) { //This checks if a user is Active
                                                if let existing_Active = item.value(forKey: "_Type") as? String {
                                                    if (existing_Active != "Inactive"){ //Actual check if active
                                                        print("found an active match at:")
                                                        print(existing_longitude)
                                                        print(user)
                                                        if (item.value(forKey: "_Type") != nil) {
                                                            if let existing_Type = item.value(forKey: "_Type") as? String {
                                                                if (existing_Type == "Pedestrian"){ //This checks to see if the found user is a Ped
                                                                    if (self.userType == "Driver"){ //This checks to see if the user is a Car (since cars are the only user receiving alerts)
                                                                        self.collisionFlag = 1
                                                                        let alertController = UIAlertController(title: "CAUTION!", message: "Please be careful as our systems indicate there is a nearby pedestrian.", preferredStyle: UIAlertController.Style.alert)
                                                                        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                                                                        self.present(alertController, animated: true, completion: nil)
                                                                        print("found an active pedestrian match at:\(existing_longitude) with \(user)") }
                                                                    
                                                                }
                                                                else if (existing_Type == "Cyclist"){ //This checks to see if the found user is a Ped
                                                                    if (self.userType == "Driver"){ //This checks to see if the user is a Car (since cars are the only user receiving alerts)
                                                                        self.collisionFlag = 1
                                                                        let alertController = UIAlertController(title: "CAUTION!", message: "Please be careful as our systems indicate there is a nearby cyclist.", preferredStyle: UIAlertController.Style.alert)
                                                                        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                                                                        self.present(alertController, animated: true, completion: nil)
                                                                        print("found an active cyclist match at:\(existing_longitude) with \(user)") }}}
                                                        }
                                                    }
                                                    else{
                                                        print("found an inactive match at:")
                                                        print(existing_longitude)
                                                        print(user)}}}
                                        }
                                        else{
                                            print("Matched itself")}}}}}
                    }//Close if collision flag statement LONGITUDE
                }//Close For Loop
            } //Close if statement
            else{
                print("No Response")}}
    }
/*Social Event Check*/
    func eventCheck(Building: String){
        if Building == "Johnson Center" && self.eventFlag == 0 && self.userType != "Driver" && self.userType != "Inactive"{//ensure no notification repeats
            self.eventFlag = 1
            let alertController = UIAlertController(title: "Nearby Event Notification", message: "We noticed you're walking by the \(Building). They have their Career Fair going on today from 3-5pm.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Thanks!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if Building == "Engineering Building" && self.eventFlag == 0 && self.userType != "Driver" && self.userType != "Inactive"{//ensure no notification repeats
            self.eventFlag = 1
            let alertController = UIAlertController(title: "Nearby Event Notification", message: "We noticed you're walking by the \(Building). They have their Senior Design Presentations going on today from 2-4pm.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Thanks!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }

        
    
     func eventCheckDB(Building: String){ //Database event function
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId" : Building, //The value you're trying to match
        ]
        dynamoDbObjectMapper.query(SafeTTesting_Events.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if(output != nil && self.userType != "Driver" && self.userType != "Inactive"){ //Only do this for Pedestrians and Cyclist
                print("Got Response")
                for item in (output?.items)! { //Loops through all matches
                    if (item.value(forKey: "_Type") != nil) { //Check if each user has an event value
                        if let existing_Event = item.value(forKey: "_Type") as? String { //Converts output to string for comparison
                            if existing_Event != "None" && self.eventFlag == 0{//ensure no notification repeats
                                self.eventFlag = 1
                                let alertController = UIAlertController(title: "Nearby Event Notification", message: "We notived you're walking by \(Building). They have their \(existing_Event) going on today.", preferredStyle: UIAlertController.Style.alert)
                                alertController.addAction(UIAlertAction(title: "Thanks!", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                            }}}}}}}
    
    
/* AWS Database Functions (WORKS) */
    func databaseFunction(){
        let latitude_val: String = self.current_latitude
        let longtitude_val: String = self.current_longitude
        let time_val: String = self.current_timestamp
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        let hello:SafeTTesting2 = SafeTTesting2()
        
        hello._Latitude = latitude_val
        hello._Longitude = longtitude_val
        hello._Type = self.userType
        hello._Building = self.current_Building
        hello._userId = AWSMobileClient.sharedInstance().username
        hello._Emergency = self.current_emergency //THIS VALUE CAN ONLY BE CHANGED IN THE DB
        hello._Time = time_val
        
        objectMapper.save(hello, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
    }
    
/* AWS Database Clear Functions (WORKS) */
    func databaseClearFunction(){
        
        let latitude_val: String = "0"
        let longtitude_val: String = "0"
        let userTypeClean: String = "Inactive"
        let timeClean: String = "N/A"
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let hello:SafeTTesting2 = SafeTTesting2()
        hello._Latitude = latitude_val
        hello._Longitude = longtitude_val
        hello._Type = userTypeClean
        hello._userId =  AWSMobileClient.sharedInstance().username
        hello._Building = "N/A" //replace with last known place
        hello._Emergency = self.current_emergency //Keep the last emergency state
        hello._Time = timeClean
        
        objectMapper.save(hello, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
    }

    
/*Localization of user to a known building (WORKS) */
    func findBuilding(){
        if (self.current_latitude != "0" && self.current_longitude != "0"){
            let index_lat = self.current_latitude.index(self.current_latitude.startIndex, offsetBy: 6)//This creates a substring of the current users' latitude
            let mySubstring_lat = self.current_latitude.prefix(upTo: index_lat)
            let index_lon = self.current_longitude.index(self.current_longitude.startIndex, offsetBy: 7)//This creates a substring of the current users' latitude
            let mySubstring_lon = self.current_longitude.prefix(upTo: index_lon)
            if (self.userType != "Driver"){ //Only do this Pedestrians and Cyclist
                if (mySubstring_lat == "38.830" || mySubstring_lat == "38.829"){ //Loops through all matches
                    if (mySubstring_lon == "-77.306" || mySubstring_lon == "-77.307" || mySubstring_lon == "-77.308"){
                        self.current_Building = "Johnson Center"
                    }
                }
            }
            if (self.userType != "Driver"){ //Only do this Pedestrians and Cyclist
                if (mySubstring_lat == "38.827"){ //Loops through all matches
                    if (mySubstring_lon == "-77.305" || mySubstring_lon == "-77.304"){
                        self.current_Building = "Engineering Building"
                    }
                }
            }
        }
        else{
            self.current_Building = "Unknown"
            print("Unable to locate user to a known building")
        }
        
    }
    
/*Emergency Event Checks*/
    func emergencyCheck(user: String){
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId" : user, //The value you're trying to match
        ]
        dynamoDbObjectMapper.query(SafeTTesting2.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if(output != nil){
                print("Got Response")
                for item in (output?.items)! { //Loops through all matches
                    if (item.value(forKey: "_Emergency") != nil) { //Check if each user has a Latitude value
                        if let existing_Emergency = item.value(forKey: "_Emergency") as? String { //Converts output to string for comparison
                            self.current_emergency = existing_Emergency
                            if (existing_Emergency == "Gun" && self.emergencyFlag == 0){ //wont repeat
                                self.emergencyFlag = 1
                                let alert = UIAlertController(title: "EMERGENCY (SHOOTER) ALERT", message: "Evacuate and mark yourself as safe.", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Safe", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
                                    self.current_emergency = "Safe"
                                    self.databaseFunction() //updatethe database
                                }))
                                alert.addAction(UIAlertAction(title: "Not Safe", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
                                    self.current_emergency = "Gun"
                                    self.databaseFunction() //updatethe database
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
                            else if (existing_Emergency == "Fire" && self.emergencyFlag == 0){ //wont repeat
                                self.emergencyFlag = 1
                                let alert = UIAlertController(title: "EMERGENCY (FIRE) ALERT", message: "Evacuate and mark yourself as safe.", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Safe", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
                                    self.current_emergency = "Safe"
                                    self.databaseFunction() //updatethe database
                                }))
                                alert.addAction(UIAlertAction(title: "Not Safe", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
                                    self.current_emergency = "Fire"
                                    self.databaseFunction() //updatethe database
                                }))
                                self.present(alert, animated: true, completion: nil)
                                
                                //let alertController = UIAlertController(title: "EMERGENCY (FIRE) ALERT", message: "Evacuate.", preferredStyle: UIAlertController.Style.alert)
                                //alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                                //self.present(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
/*User Login and Logout Functionality as well as AWS Connections*/
    @IBAction func loggingOut(_ sender: UIButton) {
        let alert = UIAlertController(title: "Leaving so soon...", message: "Are you sure you want to log out?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            self.showSignOut()
            self.scSegment.selectedSegmentIndex = -1
            self.cleanLocationData()
            self.databaseClearFunction()
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
/* Initializing the AWSMobileClient and take action based on current user state*/
    func initializeAWSMobileClient() {
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            
            //self.addUserStateListener() // Register for user state changes
            
            if let userState = userState {
                switch(userState){
                case .signedIn: // is Signed IN
                    print("Logged In")
                    print("Cognito Identity Id (authenticated): \(String(describing: AWSMobileClient.sharedInstance().identityId)))")
                case .signedOut: // is Signed OUT
                    print("Logged Out")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutUserPoolsTokenInvalid: // User Pools refresh token INVALID
                    print("User Pools refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutFederatedTokensInvalid: // Facebook or Google refresh token INVALID
                    print("Federated refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                default:
                    AWSMobileClient.sharedInstance().signOut()
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    // Use the iOS SDK drop-in Auth UI to show login options to user (Basic auth, Google, or Facebook)
    // Note: The view controller implementing the drop-in auth UI needs to be associated with a Navigation Controller.
/*Present the navigation home screen by checking if user is logged in*/
    func showSignIn() {
        AWSMobileClient.sharedInstance()
            .showSignIn(navigationController: self.navigationController!,
                        signInUIOptions: SignInUIOptions(
                            canCancel: false,
                            logoImage: UIImage(named: "signInLogo"), //how to customize the logo
                            backgroundColor: UIColor.black)) { (result, err) in
                                //handle results and errors
        }
        
        AWSMobileClient.sharedInstance().showSignIn(navigationController: self.navigationController!, {
            (userState, error) in
            if(error == nil){   // Successful signin
                DispatchQueue.main.async {
                    print("User successfully logged in")
                }
            }
        })
        
        
    }
    func showSignOut() {
        AWSMobileClient.sharedInstance().signOut()
        
        DispatchQueue.main.async {
            self.showSignIn()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

