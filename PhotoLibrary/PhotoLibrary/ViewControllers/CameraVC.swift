//
//  CameraVC.swift
//  PhotoLibrary
//
//  Created by Pavlov Matthew on 14.04.2021.
//

import UIKit
import AVFoundation

//кастомный камера вью
class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var takeUrgent: ((UrgentPhoto) -> ())?
    var takeUsual: ((UsualPhoto) -> ())?

    @IBOutlet var cameraVIew: UIView!
    @IBOutlet var photoView: UIImageView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var isTruePhoto = true
    
   override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Невозможно получить доступ к задней камере")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Невозможно получить доступ к задней камере:  \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraVIew.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self?.videoPreviewLayer.frame = (self?.cameraVIew.bounds)!
            }
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    //кнопка смены альбома для сохранения фотографии
    @IBAction func quitCamera(_ sender: Any) {
        let ac = UIAlertController(title: "В какой ряд добавить фото?", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Срочные", style: .default) { [weak self] _ in
            self?.isTruePhoto = true
        })
        ac.addAction(UIAlertAction(title: "Обычные", style: .default) { [weak self] _ in
            self?.isTruePhoto = false
        })
        present(ac, animated: true)
    }
    
    //для просмотра получившейся фотографии
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        guard let image = UIImage(data: imageData) else { return }
        photoView.image = image
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        if isTruePhoto {
            takeUrgent?(UrgentPhoto(name: "Unknown", image: imageName))
        } else {
            takeUsual?(UsualPhoto(name: "Unknown", image: imageName))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}
