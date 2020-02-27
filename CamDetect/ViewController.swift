//
//  ViewController.swift
//  CamDetect
//
//  Created by Justin Hsu on 8/18/18.
//  Copyright © 2018 Justin Hsu. All rights reserved.
//

import UIKit
import AVKit
import Vision

var linkObj = "Chair"
var resultsObj = [VNClassificationObservation]()

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var textBg: UIImageView!
    @IBOutlet weak var objLabel: UILabel!
    @IBOutlet weak var infoText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///////////////////////////// Set up camera ///////////////////////////
        let captureSesh = AVCaptureSession()
        captureSesh.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSesh.addInput(input)
        
        captureSesh.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSesh)
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(previewLayer)

        textBg.layer.zPosition = 1
        infoText.layer.zPosition = 2
        infoText.isEditable = false
        objLabel.layer.zPosition = 2
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSesh.addOutput(dataOutput)
        ///////////////////////////////////////////////////////////////////////
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let params = ["token": "JRZMKTSQQJTRUIHTLNQYFIYWTWWUJRASLABQOSAPPVVTBHHOPRDOOEWDWBAMCLRT",
                      "source": "ebay",
                      "country": "us",
                      "topic": "product_and_offers",
                      "key": "term",
                      "values": linkObj] as Dictionary<String, String>

        var request = URLRequest(url: URL(string: "https://api.priceapi.com/v2/jobs")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print(response!)
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(json)
            } catch {
                print("error")
            }
        })

        task.resume()

        
        print(linkObj)
        objLabel.text = linkObj
    }
    
    // Get object name from camera output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let resNetModel = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: resNetModel) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObs = results.first else { return }
            
            DispatchQueue.main.async {
            }
                    
            resultsObj = results
            
            var objRaw = String(firstObs.identifier)
            if (objRaw.contains(",")) {
                if let first = objRaw.components(separatedBy: ",").first {
                    // Do something with the first component.
                    objRaw = first
                }
            }
            
            linkObj = objRaw
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func makeModelGuess(model_in: VNCoreMLModel) -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: model_in) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObs = results.first else { return }
            
            DispatchQueue.main.async {
            }
                    
            resultsObj = results
            
            var objRaw = String(firstObs.identifier)
            if (objRaw.contains(",")) {
                if let first = objRaw.components(separatedBy: ",").first {
                    // Do something with the first component.
                    objRaw = first
                }
            }
            
            linkObj = objRaw
        }
        return request
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

