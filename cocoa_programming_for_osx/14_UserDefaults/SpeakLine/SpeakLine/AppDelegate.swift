//
//  AppDelegate.swift
//  SpeakLine
//
//  Created by mcxiaoke on 16/4/27.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var mainWindowController:MainWindowController?

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    let mwc = MainWindowController()
    mwc.showWindow(self)
    self.mainWindowController = mwc
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }


}

