//
//  CameraViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol CameraDelegate {
    func showCameraOptions()
    func hideCameraOptions()
    func showEditOptions()
    func hideEditOptions()
    func takingPhoto()
    func takingVideo()
}

class CameraViewController:UIViewController, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate {
    
    
    var cameraOutputView: UIView!
    var videoCaptureView: UIView!
    var imageCaptureView: UIImageView!
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoFileOutput: AVCaptureMovieFileOutput?
    var videoUrl: URL?
    var cameraDevice: AVCaptureDevice?
    var flashMode:FlashMode = .Off
    var cameraMode:CameraMode = .Back
    
    var delegate: CameraDelegate?
    
    var recordBtnRef: CameraButton!
    
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let definiteBounds = UIScreen.main.bounds
        view.backgroundColor = UIColor.black
        
        cameraOutputView = UIView(frame: view.bounds)
        view.addSubview(cameraOutputView)
        
        videoCaptureView = UIView(frame: view.bounds)
        view.addSubview(videoCaptureView)
        
        imageCaptureView = UIImageView(frame: view.bounds)
        view.addSubview(imageCaptureView)

        cameraState = .Initiating
        
    }
    
    var cameraState:CameraState = .Off
        {
        didSet {
            switch cameraState {
            case .Off:
                break
            case .Initiating:
                reloadCamera()
                break
            case .Running:
                imageCaptureView.image  = nil
                imageCaptureView.isHidden = true

                playerLayer?.player?.pause()
                playerLayer?.removeFromSuperlayer()
                playerLayer?.player = nil
                playerLayer = nil

                delegate?.showCameraOptions()
                delegate?.hideEditOptions()
                recordBtnRef.isHidden = false
                break
            case .DidPressTakePhoto:

                delegate?.takingPhoto()
                delegate?.hideCameraOptions()
                recordBtnRef.isHidden = true
                break
            case .PhotoTaken:
                resetProgress()
                imageCaptureView.isHidden = false
                videoCaptureView.isHidden = true
                delegate?.showEditOptions()
                break
            case .Recording:
                delegate?.takingVideo()
                delegate?.hideCameraOptions()
                break
            case .VideoTaken:
                resetProgress()
                imageCaptureView.isHidden  = true
                videoCaptureView.isHidden  = false
                delegate?.showEditOptions()
                delegate?.hideCameraOptions()
                recordBtnRef.isHidden = true
                break
            }
        }
    }
    
    func reloadCamera() {
        destroyCameraSession()
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset1280x720
        
        if cameraMode == .Front
        {
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            
            for device in videoDevices!{
                if let device = device as? AVCaptureDevice
                {
                    if device.position == AVCaptureDevicePosition.front {
                        cameraDevice = device
                        break
                    }
                }
            }
        }
        else
        {
            cameraDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        do {
            
            let input = try AVCaptureDeviceInput(device: cameraDevice)
            
            videoFileOutput = AVCaptureMovieFileOutput()
            self.captureSession!.addOutput(videoFileOutput)
            
 
            if captureSession?.canAddInput(input) != nil {
                captureSession?.addInput(input)
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if (captureSession?.canAddOutput(stillImageOutput) != nil) {
                    captureSession?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.session.usesApplicationAudioSession = false
                    
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer?.frame = cameraOutputView.bounds
                    cameraOutputView.layer.addSublayer(previewLayer!)
                    captureSession?.startRunning()
                    
                    cameraState = .Running
                }
            }
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    func destroyCameraSession() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        playerLayer?.player = nil
        playerLayer = nil
    }
    
    func destroyVideoPreview() {
        NotificationCenter.default.removeObserver(self)
        playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
    }
    
    func didPressTakePhoto()
    {
        if cameraState != .Running { return }
        cameraState = .DidPressTakePhoto
        
        AudioServicesPlayAlertSound(1108)
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler:{
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    var image:UIImage!
                    image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    if self.cameraMode == .Front {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    } else {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    }
                    
                    DispatchQueue.main.async {
                        self.cameraState = .PhotoTaken
                        self.imageCaptureView.image = image
                    }
                }
            })
        }
    }
    
    
    let maxDuration = CGFloat(10)
    
    func updateProgress() {
        if progress > 0.99 {
            progressTimer.invalidate()
            videoFileOutput?.stopRecording()
            recordBtnRef.updateProgress(progress: 1.0)
        } else {
            progress = progress + (CGFloat(0.025) / maxDuration)
            recordBtnRef.updateProgress(progress: progress)
        }
        
    }
    
    func resetProgress() {
        progress = 0
        recordBtnRef.resetProgress()
    }
    
    
    func pressed(state: UIGestureRecognizerState)
    {
        switch state {
        case .began:
            if cameraState == .Running {
                recordVideo()
            }
            
            break
        case .ended:
            if cameraState == .Recording {
                videoFileOutput?.stopRecording()
            }
            
            break
        default:
            break
        }
    }
    
    func recordVideo() {
        let audioDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do {
            
            let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            let canAddAudioInput = self.captureSession!.canAddInput(audioInput)
            if self.captureSession!.canAddInput(audioInput) {
               self.captureSession!.addInput(audioInput)
            }
        } catch {
            print("Unable to add audio device to the recording.")
        }
        cameraState = .Recording
        progressTimer = Timer.scheduledTimer(timeInterval: 0.025, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent("temp.mp4")//documentsURL.URLByAppendingPathComponent("temp.mp4")
        
        // Do recording and save the output to the `filePath`
        videoFileOutput!.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        progressTimer.invalidate()
        videoUrl = outputFileURL
        
        let item = AVPlayerItem(url: outputFileURL as URL)
        videoPlayer.replaceCurrentItem(with: item)
        playerLayer = AVPlayerLayer(player: videoPlayer)
        
        playerLayer!.frame = self.view.bounds
        self.videoCaptureView.layer.addSublayer(playerLayer!)
        
        playerLayer!.player?.play()
        playerLayer!.player?.actionAtItemEnd = .none
        cameraState = .VideoTaken
        loopVideo()
        return
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        cameraState = .Recording
        return
    }
    
    func loopVideo() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.playerLayer?.player?.seek(to: kCMTimeZero)
            self.playerLayer?.player?.play()
        }
    }
    
    func endLoopVideo() {
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime, name: nil, object: nil)
    }
   
    
    func switchCamera(sender:UIButton!) {
        switch cameraMode {
        case .Back:
            cameraMode = .Front
            break
        case .Front:
            cameraMode = .Back
            break
        }
        reloadCamera()
    }
    
    var pivotPinchScale:CGFloat!
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //        if gestureRecognizer === pinchGesture {
        //            let loc = touch.location(in: view)
        //            if loc.y > recordBtn.frame.origin.y - 8 {
        //                return false
        //            }
        //        }
        return true
    }
    
    func handlePinchGesture(gesture:UIPinchGestureRecognizer) {
        
        guard let device = cameraDevice else { return }
        do {
            try device.lockForConfiguration()
            switch gesture.state {
            case .began:
                self.pivotPinchScale = device.videoZoomFactor
            case .changed:
                var factor = self.pivotPinchScale * gesture.scale
                factor = max(1, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = factor
            default:
                break
            }
            device.unlockForConfiguration()
        } catch {
            // handle exception
        }
    }
    
    var animateActivity: Bool!
    func autoFocusGesture(_ gestureRecognizer: UITapGestureRecognizer){
        print("YAH")
        let touchPoint: CGPoint = gestureRecognizer.location(in: self.cameraOutputView)
        //GET PREVIEW LAYER POINT
        let convertedPoint = self.previewLayer!.captureDevicePointOfInterest(for: touchPoint)
        
        //Assign Auto Focus and Auto Exposour
        if let device = cameraDevice {
            do {
                try! device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported{
                    //Add Focus on Point
                    device.focusPointOfInterest = convertedPoint
                    device.focusMode = AVCaptureFocusMode.autoFocus
                }
                
                if device.isExposurePointOfInterestSupported{
                    //Add Exposure on Point
                    device.exposurePointOfInterest = convertedPoint
                    device.exposureMode = AVCaptureExposureMode.autoExpose
                }
                device.unlockForConfiguration()
            }
        }
        
        let circleContainer = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        let circle = UIView(frame: circleContainer.bounds)
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.borderWidth = 1.0
        circle.cropToCircle()
        
        circleContainer.layer.masksToBounds = false
        circleContainer.applyShadow(radius: 3.0, opacity: 0.5, height: 0.0, shouldRasterize: false)
        circleContainer.center = touchPoint
        circleContainer.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        circleContainer.alpha = 0.0
        
        
        circleContainer.addSubview(circle)
        view.addSubview(circleContainer)
        
        UIView.animate(withDuration: 0.20, delay: 0.0, options: .curveEaseOut, animations: {
            circleContainer.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            circleContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 0.25, options: .curveEaseIn, animations: {
                circleContainer.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                circleContainer.alpha = 0.0
            }, completion: { _ in
                circleContainer.removeFromSuperview()
            })
        })
        
        
    }
    
    
    
}
