//
//  DrawView.swift
//  TouchTracker
//
//  Created by Xiaoke Zhang on 2017/8/17.
//  Copyright © 2017年 Xiaoke Zhang. All rights reserved.
//

import UIKit

class DrawView: UIView {
    var cornerSize:CGFloat = 0
    var topLeftCorner:CGRect = CGRect.zero
    var topRightCorner:CGRect = CGRect.zero
    var bottomLeftCorner:CGRect = CGRect.zero
    var bottomRightCorner:CGRect = CGRect.zero
    
    var currentWidth:Int = 10
    var currentLines:[NSValue:Line] = [:]
    var finishedLines:[Line] = []
    weak var selectedLine:Line?
    
    var moveRecongnizer: UIPanGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        print("setup bounds=\(self.bounds)")
        
        setupCorners()
        
        self.isMultipleTouchEnabled = true
        self.backgroundColor = UIColor.white
//        load()
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gs:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delaysTouchesBegan = true
        self.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(gs:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.require(toFail: doubleTap)
        singleTap.delaysTouchesBegan = true
        //self.addGestureRecognizer(singleTap)
        
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(gs:)))
        self.addGestureRecognizer(longPress)
        
        let move = UIPanGestureRecognizer(target: self, action: #selector(move(gs:)))
        move.delegate = self
        move.maximumNumberOfTouches = 1
        move.cancelsTouchesInView = false
        self.moveRecongnizer = move
        self.addGestureRecognizer(move)
        
//        let threeSwipe = UISwipeGestureRecognizer.init(target: self, action: #selector(threeSwipe(gs:)))
//        threeSwipe.numberOfTouchesRequired = 3
//        threeSwipe.cancelsTouchesInView = true
//        threeSwipe.direction = .up
//        self.addGestureRecognizer(threeSwipe)
    }
    
    func setupCorners() {
        let width = self.bounds.width
        let height = self.bounds.height
        let size = min(width, height) / 6
        self.cornerSize = size
        self.topLeftCorner = CGRect(x: 0, y: 0,
                                    width: size, height: size)
        self.topRightCorner = CGRect(x: width - size, y: 0,
                                     width: size, height: size)
        self.bottomLeftCorner = CGRect(x: 0, y: height - size,
                                       width: size, height: size)
        self.bottomRightCorner = CGRect(x: width - size, y: height - size,
                                        width: size, height: size)
        print("topLeftCorner=\(topLeftCorner)")
        print("topRightCorner=\(topRightCorner)")
        print("bottomLeftCorner=\(bottomLeftCorner)")
        print("bottomRightCorner=\(bottomRightCorner)")
    }
    
//    func threeSwipe(gs:UIGestureRecognizer) {
//        print("threeSwipe")
//        self.currentLines.removeAll()
//        self.finishedLines.removeAll()
//        setNeedsDisplay()
//    }
    
    func longPress(gs:UIGestureRecognizer) {
        switch gs.state {
        case .began:
            print("longPress began")
            let point = gs.location(in: self)
            self.selectedLine = lineAt(point: point)
            if let _ = self.selectedLine {
                self.currentLines.removeAll()
            }
        case .ended:
            print("longPress end")
            self.selectedLine = nil
        default:
            break
        }
        setNeedsDisplay()
    }
    
    func singleTap(gs: UIGestureRecognizer) {
        print("singleTap \(gs.location(in: self))")
        let point = gs.location(in: self)
        checkPoint(point)
    }
    
    func doubleTap(gs: UIGestureRecognizer) {
        let point = gs.location(in: self)
        print("doubleTap point=\(point)")
        if topLeftCorner.contains(point) {
            clearAll()
        } else if topRightCorner.contains(point) {
            removeLast()
        } else if bottomLeftCorner.contains(point) {
            clearAll()
        } else if bottomRightCorner.contains(point) {
            removeLast()
        } else {
            checkPoint(point)
        }
    }
    
    func clearAll() {
        self.currentLines.removeAll()
        self.finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    func removeLast() {
        guard self.finishedLines.count > 0 else { return }
        self.finishedLines.removeLast()
        setNeedsDisplay()
    }
    
    func checkPoint(_ point: CGPoint) {
        self.selectedLine = lineAt(point: point)
        setNeedsDisplay()
        if let _ = self.selectedLine {
            self.becomeFirstResponder()
            let menu = UIMenuController.shared
            let colorItem = UIMenuItem(title: "Color", action: #selector(colorLine(_:)))
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteLine(_:)))
            menu.menuItems = [colorItem, deleteItem]
            menu.setTargetRect(CGRect(x: point.x, y:point.y, width: 2, height: 2), in: self)
            menu.isMenuVisible = true
        } else {
            UIMenuController.shared.isMenuVisible = false
        }
    }
    
    func updateSpeed(gs: UIPanGestureRecognizer) {
        let velocity = gs.velocity(in: self)
        // min=0 20px max=6000 5px
        let speed = min(sqrt(velocity.x*velocity.x + velocity.y*velocity.y), 6000)
        self.currentWidth = max(Int(20 - speed/6000 * 20), 2)
//        print("updateSpeed speed=\(speed) currentWidth=\(currentWidth)")
    }
    
    func move(gs: UIPanGestureRecognizer) {
        updateSpeed(gs: gs)
        guard !UIMenuController.shared.isMenuVisible else { return }
        guard let line = self.selectedLine else { return }
        switch gs.state {
        case .changed:
            let translation = gs.translation(in: self)
            line.begin.x += translation.x
            line.begin.y += translation.y
            line.end.x += translation.x
            line.end.y += translation.y
            gs.setTranslation(CGPoint.zero, in: self)
            setNeedsDisplay()
        default:
            break
        }
    }
    
    func colorLine(_ id: Any?) {
        if let line = self.selectedLine {
            print("colorLine")
            self.selectedLine = nil
            line.color = UIColor.random()
            setNeedsDisplay()
        }
    }
    
    func deleteLine(_ id: Any?) {
        if let line = self.selectedLine {
            print("deleteLine")
            self.finishedLines.remove(object: line)
            setNeedsDisplay()
        }
    }
    
    func lineAt(point: CGPoint) -> Line? {
        for line in self.finishedLines {
            let start = line.begin
            let end = line.end
            var t = CGFloat(0.0)
            while t <= 1.0 {
                let x = start.x + t * (end.x - start.x)
                let y = start.y + t * (end.y - start.y)
                if hypot(x - point.x, y - point.y) < 10.0 {
                    print("found line: \(line)")
                    return line
                }
                t += 0.05
            }
        }
        return nil
    }
    
    func getLinesStoreFile() -> String {
        let fileDir = try! FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
        return fileDir.appendingPathComponent("finishedLines.dat").path
    }
    
    func getColorsStoreFile() -> String {
        let fileDir = try! FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
        return fileDir.appendingPathComponent("finishedLineColors.dat").path
    }
    
    func save() {
        let ret = NSKeyedArchiver.archiveRootObject(self.finishedLines, toFile: getLinesStoreFile())
        print("save result=\(ret)")
    }
    
    func load() {
        if let lines = NSKeyedUnarchiver.unarchiveObject(withFile: getLinesStoreFile()) as? [Line] {
            self.finishedLines = lines
        }
        setNeedsDisplay()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func drawRect(_ rect: CGRect, fill: Bool) {
        let bp = UIBezierPath()
        bp.move(to: CGPoint(x: rect.minX, y: rect.minY))
        bp.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        bp.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        bp.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        bp.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        if fill {
            bp.fill()
        } else {
            bp.stroke()
        }
        
    }
    
    func drawCorners() {
        UIColor(hex: "F8F8F8").set()
        drawRect(topLeftCorner, fill: false)
        drawRect(topRightCorner, fill: false)
        drawRect(bottomLeftCorner, fill: false)
        drawRect(bottomRightCorner, fill: false)
    }
    
    override func draw(_ rect: CGRect) {
        drawCorners()
        
        for line in finishedLines {
            line.color.set()
            strokeLine(line)
        }
        
        if let line = self.selectedLine {
            UIColor.yellow.set()
            strokeLine(line)
        }
        
        for line in currentLines.values {
            line.color.set()
            strokeLine(line, width: currentWidth)
        }
    }
    
    func strokeLine(_ line: Line, width: Int? = nil) {
        let bp = UIBezierPath()
        bp.lineWidth = CGFloat(width ?? line.width)
        bp.lineCapStyle = .round
        bp.move(to: line.begin)
        bp.addLine(to: line.end)
        bp.stroke()
    }
    
    // MARK: TouchEvent
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(#function) \(currentWidth)")
        for t in touches {
            let p = t.location(in: self)
            let line = Line(begin: p, end: p)
            // using memory address
            let key = NSValue(nonretainedObject: t)
            self.currentLines[key] = line
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("\(#function) \(touches.map({$0.location(in: self)}))")
        for t in touches {
            let key = NSValue(nonretainedObject: t)
            if let line = self.currentLines[key] {
                line.end = t.location(in: self)
                self.currentLines[key] = line
            }
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(#function) \(currentWidth)")
        for t in touches {
            let key = NSValue(nonretainedObject: t)
            if let line = self.currentLines[key] {
                line.width = currentWidth
                self.finishedLines.append(line)
                self.currentLines[key] = nil
            }
        }
        setNeedsDisplay()
//        save()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(#function) \(touches.map({$0.location(in: self)}))")
        for t in touches {
            let key = NSValue(nonretainedObject: t)
            self.currentLines[key] = nil
        }
        setNeedsDisplay()
//        save()
    }
    
}

extension DrawView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.moveRecongnizer
    }
    
}
