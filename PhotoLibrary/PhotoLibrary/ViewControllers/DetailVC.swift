//
//  DetailVC.swift
//  PhotoLibrary
//
//  Created by Pavlov Matthew on 15.04.2021.
//

import UIKit

//Вью для детального просмотра фотографии
class DetailVC: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var urgentPic: UrgentPhoto?
    var usualPic: UsualPhoto?
    
    var urgentPhoto = [UrgentPhoto]()
    var usualPhoto = [UsualPhoto]()
    
    var isTrue = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let imageToLoad = urgentPic?.image {
            let path = getDocumentsDirectory().appendingPathComponent(imageToLoad)
            imageView.image = UIImage(contentsOfFile: path.path)
            isTrue = true
        } else if let imageToLoad = usualPic?.image {
            let path = getDocumentsDirectory().appendingPathComponent(imageToLoad)
            imageView.image = UIImage(contentsOfFile: path.path)
            isTrue = false
        }

        //возврат к предыдущему контроллеру (по ТЗ)
        let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(returnVC(gestureRecognizer:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    @objc func returnVC(gestureRecognizer: UISwipeGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }
}
