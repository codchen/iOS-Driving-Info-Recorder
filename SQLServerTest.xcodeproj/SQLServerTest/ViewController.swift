//
//  ViewController.swift
//  SQLServerTest
//
//  Created by Xiaoyu Chen on 5/14/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion

class ViewController: UIViewController, SQLClientDelegate, UITextFieldDelegate, CLLocationManagerDelegate {
    
    var myClient = SQLClient.sharedInstance()
    
    @IBOutlet weak var signOut: UIButton!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signUp: UIButton!
    @IBOutlet weak var signIn: UIButton!
    @IBOutlet weak var labelU: UILabel!
    @IBOutlet weak var labelP: UILabel!
    @IBOutlet weak var preview: UIView!
    
    @IBOutlet weak var controlBtn: UIButton!
    var started = false
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var stillImageOutput: AVCaptureStillImageOutput?
    var lastCapturedData: NSData?
    var fmt: NSDateFormatter?
    var fmtSQL: NSDateFormatter?
    var timer: NSTimer?
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var currentSpeed: Double?
    var motionManager: CMMotionManager?
    var frameNumber = 0
    var myUsername: String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.username.returnKeyType = UIReturnKeyType.Done
        self.password.returnKeyType = UIReturnKeyType.Done
        self.username.delegate = self
        self.password.delegate = self
        self.username.clearsOnBeginEditing = true
        self.password.clearsOnBeginEditing = true
        self.password.secureTextEntry = true
        self.controlBtn.hidden = true
        self.signOut.hidden = true
        self.preview.hidden = true
        
        self.myClient.delegate = self
        
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if (device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if (captureDevice != nil) {
                        beginSession()
                    }
                }
            }
        }
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = preview.bounds
        preview.layer.addSublayer(previewLayer)
        
        fmt = NSDateFormatter()
        fmt?.dateFormat = "yyyy_MM_dd'T'HH_mm_ss"
        
        fmtSQL = NSDateFormatter()
        fmtSQL?.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.05
        motionManager?.startAccelerometerUpdates()
    }
    @IBAction func Connect(sender: AnyObject) {
        if (username == nil || password == nil) {
            return
        }
        else{
            if (myUsername == nil) {
                alert("Cannot connect", content: "Please log in first", button: "OK")
                return
            }
        }
        
        if (!started) {
            if (timer == nil) {
                timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerFunction", userInfo: nil, repeats: true)
                timer?.fire()
                started = true
                dispatch_async(dispatch_get_main_queue()) {
                    self.controlBtn.setTitle("End", forState: UIControlState.Normal)
                }
            }
        }
        else {
            if (timer != nil) {
                timer?.invalidate()
                started = false
                timer = nil
                dispatch_async(dispatch_get_main_queue()) {
                    self.controlBtn.setTitle("Start", forState: UIControlState.Normal)
                }
            }
        }
    }
    
    @IBAction func signIn(sender: AnyObject) {
        if (username.text == "" || password.text == "") {
            alert("Invalid sign in", content: "Please enter both username and password", button: "OK")
            return
        }
        else{
            if (started) {
                alert("Invalid sign in", content: "Cannot sign up while recording", button: "OK")
                return
            }
        }
        self.username.resignFirstResponder()
        self.password.resignFirstResponder()
        self.myClient.connect("10.60.107.54:50539", username: "Tj_iDriver", password: "tjrdlabserver@1234", database: "Tj_iDrive") {success in
            if (success) {
                
                self.myClient.execute("SELECT * FROM driver WHERE d_username='\(self.username.text)' AND d_password='\(self.password.text)'") {result in
                    println(5)
                    for table in result {
                        if table.count == 0 {
                            self.alert("Invalid log in", content: "Invalid usename and/or password", button: "Cancel")
                        }
                        else {
                            self.myUsername = self.username.text
                            self.alert("Success", content: "You have successfully logged in", button: "OK")
                            self.controlBtn.hidden = false
                            self.signOut.hidden = false
                            self.preview.hidden = false
                            self.signIn.hidden = true
                            self.signUp.hidden = true
                            self.username.hidden = true
                            self.password.hidden = true
                            self.labelP.hidden = true
                            self.labelU.hidden = true
                            self.username.text = ""
                            self.password.text = ""
                        }
                    }
                    self.myClient.disconnect()
                }
            }
        }
    }
    @IBAction func signOut(sender: AnyObject) {
        if (started) {
            if (timer != nil) {
                timer?.invalidate()
                started = false
                timer = nil
                dispatch_async(dispatch_get_main_queue()) {
                    self.controlBtn.setTitle("Start", forState: UIControlState.Normal)
                }
            }
        }
        self.controlBtn.hidden = true
        self.signOut.hidden = true
        self.signIn.hidden = false
        self.signUp.hidden = false
        self.username.hidden = false
        self.password.hidden = false
        self.labelU.hidden = false
        self.labelP.hidden = false
        self.preview.hidden = true
        self.myUsername = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        println(textField.text)
        return true
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        currentLocation = locations.last as? CLLocation
        currentSpeed = currentLocation?.speed
    }
    
    func error(error: String!, code: Int32, severity: Int32) {
        println(error)
        NSLog("Error %d: %s (severity %d)", code, error,severity)
    }
    
    func timerFunction() {
        takePicture()
        let date = NSDate();
        uploadImage(date)
        uploadInfo(date)
    }
    
    func takePicture() {
        
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                var dataProvider = CGDataProviderCreateWithCFData(imageData)
                var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                
                //Save the captured preview to image
                //UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
                self.lastCapturedData = UIImageJPEGRepresentation(image, 0.8)
                self.frameNumber++
            })
        }
    }
    func uploadImage(date: NSDate) {
        if (lastCapturedData != nil) {
            let postURL = NSURL(string: "http://rerc.tongji.edu.cn/RERCUpload/uploads/receive_image.php");
            let fileName = myUsername! + "_image_" + fmt!.stringFromDate(date)
            var request = NSMutableURLRequest(URL: postURL!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60)
            request.HTTPMethod = "POST"
            let boundary = "----WebKitFormBoundarycC4YiaUFwM44F6rT"
            let contentType = "multipart/form-data; boundary=\(boundary)"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            var body = NSMutableData()
            appendData("\r\n--\(boundary)\r\n", data: body)
            appendData("Content-Disposition: form-data; name=\"username\"\r\n\r\n", data: body)
            appendData(myUsername!, data: body)
            appendData("\r\n--\(boundary)\r\n", data: body)
            appendData("Content-Disposition: form-data; name=\"userfile\"; filename=\"\(fileName).jpg\"\r\n", data: body)
            appendData("Content-Type: application/octet-stream\r\n\r\n", data: body)
            body.appendData(NSData(data: lastCapturedData!))
            appendData("\r\n--\(boundary)-\r\n", data: body)
            request.HTTPBody = body
            var error:NSError?
            var responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: &error)
            if (error != nil) {
                NSLog("Error: \(error?.localizedDescription)")
            }
            let returnString = NSString(data: responseData!, encoding: NSUTF8StringEncoding)
            NSLog("return string = \(returnString)")
            lastCapturedData = nil
        }
    }
    
    func uploadInfo(date: NSDate) {
        self.myClient.connect("10.60.107.54:50539", username: "Tj_iDriver", password: "tjrdlabserver@1234", database: "Tj_iDrive") {success in
            if (success) {
                var realSpeed: Double!
                if (self.currentSpeed < 0) {
                    realSpeed = 0
                }
                else {
                    realSpeed = self.currentSpeed
                }
                self.myClient.execute("INSERT INTO driveInfo VALUES(NULL, '\((self.fmtSQL?.stringFromDate(date))!)', '\(self.myUsername!)', \((self.motionManager?.accelerometerData.acceleration.x)!), \((self.motionManager?.accelerometerData.acceleration.y)!), \((self.motionManager?.accelerometerData.acceleration.z)!), \((realSpeed)!), \((self.currentLocation?.coordinate.latitude)!), \((self.currentLocation?.coordinate.longitude)!), NULL, \(self.frameNumber), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)") {result in
                    self.myClient.disconnect()
                }
            }
        }
    }
    
    func beginSession() {
        var error: NSError?
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &error))
        if (error != nil) {
            println("error: \(error!.localizedDescription)")
        }
        captureSession.startRunning()
    }
    
    func alert(title: String, content: String, button: String) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: button, style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func appendData(content: String, data: NSMutableData) {
        data.appendData(content.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
    }
    
    deinit {
        locationManager?.stopUpdatingLocation()
        motionManager?.stopAccelerometerUpdates()
    }
}

