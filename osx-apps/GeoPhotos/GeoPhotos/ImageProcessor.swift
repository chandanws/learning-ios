//
//  ImageProcessor.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/9.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa
import CoreLocation

class ImageProcessor {
  let geocoder = CLGeocoder()
  let sizeFormatter = NSByteCountFormatter()
  
  var rootURL:NSURL?
  var images:[ImageItem]?
  var timestamp:NSDate?
  var coordinate:CLLocationCoordinate2D?
  var altitude: Double?
  var savingIndex:Int?
  var restoringIndex:Int?
  var hasBackup = false
  
  func geocode(completionHandler:(CLPlacemark?) -> Void) {
    guard let coordinate = self.coordinate else { return }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
      print("geo code \(error)")
      completionHandler(placemarks?.first)
    }
  }
  
  func save(backupOriginal: Bool, completionHandler: (Int, String) -> Void, processHandler:((ImageItem, Int, Int) -> Void)? = nil){
    print("save timestamp:\(self.timestamp)")
    print("save altitude:\(self.altitude)")
    print("save coordinate:\(self.coordinate)")
    guard self.rootURL != nil else { completionHandler(-1, "rootURL is nil"); return  }
    guard let coordinate = self.coordinate else { completionHandler(-1, "coordinate is nil"); return }
    guard let images = self.images else { completionHandler(-1, "No images found"); return }
    let properties:[String:AnyObject] = [
      kCGImagePropertyGPSSpeed as String : 0,
      kCGImagePropertyGPSSpeedRef as String : "K",
      kCGImagePropertyGPSAltitudeRef as String : 0,
      kCGImagePropertyGPSImgDirection as String : 0.0,
      kCGImagePropertyGPSImgDirectionRef as String : "T",
      kCGImagePropertyGPSLatitude as String : Double.abs(coordinate.latitude),
      kCGImagePropertyGPSLatitudeRef as String : coordinate.latitude > 0 ? "N" : "S",
      kCGImagePropertyGPSLongitude as String : Double.abs(coordinate.longitude),
      kCGImagePropertyGPSLongitudeRef as String : coordinate.longitude > 0 ? "E" : "W",
    ]
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let fileManager = NSFileManager()
      let total = images.count
      var savedCount = 0
      self.savingIndex = nil
      images.enumerate().forEach({ (index, image) in
        print("processing \(image.name) at \(index)")
        self.savingIndex = index
        processHandler?(image, index, total)
        let date = self.timestamp ?? image.timestamp
          ?? image.exifDate ?? image.createdAt
        var gpsProperties = properties
        let dateStr = DateFormatter.stringFromDate(date)
        let dateTime = dateStr.componentsSeparatedByString(" ")
        gpsProperties[kCGImagePropertyGPSDateStamp as String] = dateTime[0]
        gpsProperties[kCGImagePropertyGPSTimeStamp as String] = dateTime[1]
        if let altitude = self.altitude {
          gpsProperties[kCGImagePropertyGPSAltitude as String] = altitude
        }
        guard let imageSource = CGImageSourceCreateWithURL(image.url, nil) else { return }
        let imageType = CGImageSourceGetType(imageSource)!
//        let imageType = image.mimeType ?? ""
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data, imageType, 1, nil) else { return }
        let metaData = [kCGImagePropertyGPSDictionary as String : gpsProperties]
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metaData)
        CGImageDestinationFinalize(imageDestination)
        if backupOriginal {
          let backupURL = image.url.URLByAppendingPathExtension("bak")
          let backupName = backupURL.lastPathComponent ?? ""
          do{
            try fileManager.replaceItemAtURL(backupURL, withItemAtURL: image.url,
              backupItemName: nil, options: .WithoutDeletingBackupItem, resultingItemURL: nil)
            image.backuped = true
            print("backup \(backupName)")
          }catch let error as NSError {
              print("backup \(error)")
          }
        }
        if let _ = try? data.writeToURL(image.url, options: NSDataWritingOptions.AtomicWrite) {
          print("processed \(image.name)")
          savedCount += 1
          image.updateProperties()
          image.modified = true
        }
      })
      self.savingIndex = nil
      if backupOriginal {
        self.hasBackup = true
      }
      dispatch_async(dispatch_get_main_queue()){
        completionHandler(savedCount, "OK")
      }
    }
  }
  
  func restore(completionHandler: (Int, String) -> Void,
               processHandler:((ImageItem, Int, Int) -> Void)? = nil){
    guard self.rootURL != nil else { completionHandler(-1, "ERROR"); return }
    guard let images = self.images else { completionHandler(-1, "ERROR"); return }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let total = images.count
      let fileManager = NSFileManager()
      var restoredCount = 0
      self.restoringIndex = nil
      images.enumerate().forEach { (index, image) in
        self.restoringIndex = index
        processHandler?(image, index, total)
        let backupURL = image.url.URLByAppendingPathExtension("bak")
        var isDirectory = ObjCBool(false)
        let fileExists = fileManager.fileExistsAtPath(backupURL.path!, isDirectory: &isDirectory)
        if fileExists && !isDirectory.boolValue {
          do{
            try fileManager.replaceItemAtURL(image.url, withItemAtURL: backupURL,
              backupItemName: nil, options: .WithoutDeletingBackupItem, resultingItemURL: nil)
            restoredCount += 1
            image.backuped = false
            image.modified = false
            print("restore \(image.name)")
          }catch let error as NSError{
            print("restore \(error)")
          }
        }
      }
      self.restoringIndex = nil
      self.hasBackup = false
      dispatch_async(dispatch_get_main_queue()){
        completionHandler(restoredCount, "OK")
      }
    }
  }
  
  func reopen(completionHandler: (Bool) -> Void){
    print("reopen: \(self.rootURL)")
    guard let url = self.rootURL else { completionHandler(false); return }
    self.loadImage(url, completionHandler: completionHandler)
  }
  
  func open(url:NSURL, completionHandler: (Bool) -> Void){
    print("open: \(url)")
    self.loadImage(url, completionHandler: completionHandler)
  }
  
  func loadImage(url:NSURL, completionHandler: (Bool) -> Void){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let urls = ExifUtils.parseFiles(url) else { return }
      let images = ExifUtils.parseURLs(urls).sort{ $0.name < $1.name }
      dispatch_async(dispatch_get_main_queue()){
        self.savingIndex = nil
        self.restoringIndex = nil
        self.hasBackup = false
        self.rootURL = url
        self.images = images
        completionHandler(true)
      }
    }
  }
  

}
