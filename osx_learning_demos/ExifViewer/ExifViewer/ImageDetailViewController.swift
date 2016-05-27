//
//  ViewController.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/5/25.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa


class ImageDetailViewController: NSViewController, NSTableViewDelegate {
  
  var imageURL:NSURL? {
    didSet {
      if let url = imageURL {
        loadFileInfo(url)
        loadImageThumb(url)
        loadImageProperties(url)
      }else{
        self.image = nil
        self.arrayController.content = nil
      }
    }
  }
  
  dynamic var image:NSImage?
  dynamic var properties: [ImagePropertyItem] = []
  
  @IBOutlet weak var filePathLabel: NSTextField!
  @IBOutlet weak var fileSizeLabel: NSTextField!
  @IBOutlet weak var fileTypeLabel: NSTextField!
  @IBOutlet weak var filePixelLabel:NSTextField!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var arrayController: NSArrayController!
  
  @IBAction func textValueDidChange(sender: NSTextField) {
    if let object = self.arrayController.selectedObjects.first {
      let row  = self.tableView.selectedRow
      print("textValueDidChange row=\(row) obj=\(object)")
    }
    print("textValueDidChange text = \(sender.objectValue)")
  }
  
  func tableViewSelectionDidChange(notification: NSNotification) {
    if let object = self.arrayController.selectedObjects.first as? ImagePropertyItem{
      let row  = self.tableView.selectedRow
      let view = self.tableView.viewAtColumn(1, row: row, makeIfNecessary: false)
      if let textField = view?.subviews[0] as? NSTextField {
        textField.editable = AllEditablePropertyKeys.contains(object.rawKey)
      }
      print("outlineViewSelectionDidChange row =\(row) obj=\(object)")
    }
  }
  
  
  func loadFileInfo(url:NSURL){
    self.filePathLabel.stringValue = url.lastPathComponent!
    if let attrs = try? NSFileManager.defaultManager().attributesOfItemAtPath(url.path!){
//      print("attrs = \(attrs)")
      self.fileSizeLabel.objectValue = attrs[NSFileSize]
      self.fileTypeLabel.objectValue = attrs[NSFileCreationDate]
    }
  }
  
  func loadImageThumb(url:NSURL){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let image = ImageHelper.thumbFromImage(url)
      dispatch_async(dispatch_get_main_queue(), { 
        self.image = image
      })
    }
  }
  
  func loadImageProperties(url: NSURL){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      if let imageSource = CGImageSourceCreateWithURL(url, nil) {
        if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?{
          let width = imageProperties[kCGImagePropertyPixelWidth] as! Int
          let height = imageProperties[kCGImagePropertyPixelHeight] as! Int
          if let imageProperties  = imageProperties as? Dictionary<String,AnyObject> {
            let properties = ImagePropertyItem.parse(imageProperties).sort { $0.key < $1.key }
              dispatch_async(dispatch_get_main_queue(), {
                self.filePixelLabel.stringValue = "\(width)X\(height)"
                self.properties = properties
              })
          }
        }
      }
    }
  }
  
  func writeProperties(url:NSURL){
    let imageSource = CGImageSourceCreateWithURL(url, nil)
    if imageSource == nil {
      return
    }
    let uti = CGImageSourceGetType(imageSource!)!
    let data = NSMutableData()
    let imageDestination = CGImageDestinationCreateWithData(data, uti, 1, nil)
    
    if imageDestination == nil {
      return
    }
    
    let gpsDict = [
      kCGImagePropertyGPSDateStamp as String : "2016:05:08",
      kCGImagePropertyGPSTimeStamp as String : "05:44:00",
      kCGImagePropertyGPSLongitudeRef as String : "E",
      kCGImagePropertyGPSLongitude as String : 108.389555,
      kCGImagePropertyGPSLatitudeRef as String : "N",
      kCGImagePropertyGPSLatitude as String : 22.785911666
    ]
    let metaDict = [kCGImagePropertyGPSDictionary as String : gpsDict]
    
    CGImageDestinationAddImageFromSource(imageDestination!, imageSource!, 0, metaDict)
    CGImageDestinationFinalize(imageDestination!)
      
//      let directory = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true).first!
//      let dateFormatter = NSDateFormatter()
//      dateFormatter.dateFormat="yyyyMMdd_HHmmss"
//      let newFileName = "\(dateFormatter.stringFromDate(NSDate())).jpg"
//      let writePath = NSURL(fileURLWithPath:directory).URLByAppendingPathComponent(newFileName)
      //        print("Image \(url) saved to \(writePath)")
      //        _ = try? data.writeToURL(writePath, options: NSDataWritingOptions.AtomicWrite)
  }
  
  // https://github.com/oopww1992/WWimageExif
  // http://oleb.net/blog/2011/09/accessing-image-properties-without-loading-the-image-into-memory/
  // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGImageProperties_Reference/index.html
  // http://sandeepc.livejournal.com/656.html
  // http://stackoverflow.com/questions/4169677/
  // CFDictionary can cast to Dictionary?
  // CFString can cast to String
  // http://stackoverflow.com/questions/32716146/cfdictionary-wont-bridge-to-nsdictionary-swift-2-0-ios9


}

