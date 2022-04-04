//
//  ViewController.swift
//  MOV-To-MP4
//
//  Created by DREAMWORLD on 04/04/22.
//

import UIKit
import MobileCoreServices
import AVFoundation

class ViewController: UIViewController {

    var original_player = AVPlayer()
    var changed_player = AVPlayer()
    
    @IBOutlet weak var original_player_view: UIView!
    @IBOutlet weak var changed_player_view: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }

    @IBAction func select_media_clicked(_ sender: UIButton) {
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status{
                DispatchQueue.main.async {
                    self.presentVideoActionSheet()
                }
            }else{
                self.alert(msg: "Please allow access to photo library from settings...")
            }
        }
      
    }

      func playFirstPlayer(url:String){
          let videoURL = NSURL(string: url)
          original_player = AVPlayer(url: videoURL! as URL)
          let playerLayerAV = AVPlayerLayer(player: original_player)
          playerLayerAV.frame = self.original_player_view.bounds
          original_player_view.layer.addSublayer(playerLayerAV)
          original_player.play()
      }

      func playChangedPlayer(url:String){
          let videoURL = NSURL(string: url)
          changed_player = AVPlayer(url: videoURL! as URL)
          let playerLayerAV = AVPlayerLayer(player: changed_player)
          playerLayerAV.frame = self.changed_player_view.bounds
          changed_player_view.layer.addSublayer(playerLayerAV)
          changed_player.play()
      }
    
    func alert(msg:String){
        let alert = UIAlertController(title: "MOV-To-MP4", message: msg, preferredStyle: .alert)
        let ohkAction = UIAlertAction(title: "OK", style: .default) { _Arg in
            //
        }
        alert.addAction(ohkAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentVideoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a media?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Record video",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                self?.presentCamera()
            }else{
                self?.alert(msg: "your device has no camera founded...")
            }
                                             
                                                
                                            }))
        actionSheet.addAction(UIAlertAction(title: "Choose video",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentVideoPicker()
                                                
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentVideoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.mediaTypes = [kUTTypeMovie as String]
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
       print(info)
        
        var mediaUrl = info[.mediaURL] as! URL
        self.playFirstPlayer(url: mediaUrl.absoluteString)
//
//        mediaUrl = mediaUrl.deletingPathExtension().appendingPathExtension("mp4")
//        self.playChangedPlayer(url: mediaUrl.absoluteString)
//
        encodeVideo(at: mediaUrl) { url, err in
            print(url)
            DispatchQueue.main.async {
                self.playChangedPlayer(url: url?.absoluteString ?? "")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func encodeVideo(at videoURL: URL, completionHandler: ((URL?, Error?) -> Void)?)  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
            
        let startDate = Date()
            
        //Create Export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completionHandler?(nil, nil)
            return
        }
            
        //Creating temp path to save the converted video
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
            
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                completionHandler?(nil, error)
            }
        }
            
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession.timeRange = range
            
        exportSession.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession.status {
            case .failed:
                print(exportSession.error ?? "NO ERROR")
                completionHandler?(nil, exportSession.error)
            case .cancelled:
                print("Export canceled")
                completionHandler?(nil, nil)
            case .completed:
                //Video conversion finished
                let endDate = Date()
                    
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful!")
                print(exportSession.outputURL ?? "NO OUTPUT URL")
                completionHandler?(exportSession.outputURL, nil)
                    
                default: break
            }
                
        })
    }
}
