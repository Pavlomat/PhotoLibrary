//
//  ViewController.swift
//  PhotoLibrary
//
//  Created by Pavlov Matthew on 12.04.2021.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate & UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var urgentCV: UICollectionView!
    @IBOutlet var usualCV: UICollectionView!
    
    var urgentPhoto = [UrgentPhoto]()
    var usualPhoto = [UsualPhoto]()
    
    var isTruePhoto = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        urgentCV.delegate = self
        urgentCV.dataSource = self
        
        usualCV.delegate = self
        usualCV.dataSource = self
        
        //используем empty data source чтобы показать фото в пустом альбоме, не могу понять что не так, в одном коллекшн вью при наличии фотографий при запуске приложения показывает пустую фотографию, при переключении на другой вью и возврате обратно все становится нормально
        urgentCV.emptyDataSetSource = self
        urgentCV.emptyDataSetDelegate = self
        
        usualCV.emptyDataSetSource = self
        usualCV.emptyDataSetDelegate = self
        
        navigationItem.title = "Галерея"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(askToAdd))
        
        //распознаем лонг тап
        let urgentRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressUrgent))
        let usualRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressUsual))
        urgentCV.addGestureRecognizer(urgentRecognizer)
        usualCV.addGestureRecognizer(usualRecognizer)
        
        let defaults = UserDefaults.standard
        
        //сохраняем фотографии для загрузки при входе в приложение
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let savedUrgent = defaults.object(forKey: "urgent") as? Data {
                let jsonDecoder = JSONDecoder()
                
                do {
                    self?.urgentPhoto = try jsonDecoder.decode([UrgentPhoto].self, from: savedUrgent)
                } catch {
                    print("Ошибка загрузки")
                }
            }
            
            if let savedUsual = defaults.object(forKey: "usual") as? Data {
                let jsonDecoder = JSONDecoder()
                
                do {
                    self?.usualPhoto = try jsonDecoder.decode([UsualPhoto].self, from: savedUsual)
                } catch {
                    print("Ошибка загрузки")
                }
            }
        }
    }
    
    //для показа фото при пустом альбоме
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "testApplicationEmptyDataSets_500px")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        urgentCV.reloadData()
        usualCV.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.urgentCV {
            return urgentPhoto.count
        } else {
            return usualPhoto.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.urgentCV {
            guard let cellA = urgentCV.dequeueReusableCell(withReuseIdentifier: "cellOne", for: indexPath) as? CellOne else {
                fatalError("Невозможно идентифицировать ячейку")
            }
            let urgent = urgentPhoto[indexPath.item]
            let path = getDocumentsDirectory().appendingPathComponent(urgent.image)
            cellA.imageView.image = UIImage(contentsOfFile: path.path)
            return cellA
        } else {
            guard let cellB = usualCV.dequeueReusableCell(withReuseIdentifier: "cellTwo", for: indexPath) as? CellTwo else {
                fatalError("Невозможно идентифицировать ячейку")
            }
            let usual = usualPhoto[indexPath.item]
            let path = getDocumentsDirectory().appendingPathComponent(usual.image)
            cellB.imageView.image = UIImage(contentsOfFile: path.path)
            return cellB
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailVC {
            if collectionView == self.urgentCV {
                vc.urgentPic = urgentPhoto[indexPath.item]
            } else {
                vc.usualPic = usualPhoto[indexPath.item]
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func askToAdd() { //спрашиваем в какой альбом добавить (срочный/обычный)
        let ac = UIAlertController(title: "Куда добавить фото?", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Срочные", style: .default) { [weak self] _ in
            self?.isTruePhoto = true
            self?.addPhoto()
        })
        ac.addAction(UIAlertAction(title: "Обычные", style: .default) { [weak self] _ in
            self?.isTruePhoto = false
            self?.addPhoto()
        })
        present(ac, animated: true)
    }
    
    func addPhoto(action: UIAlertAction! = nil) { //добавляем фото в альбом
        if let vc = storyboard?.instantiateViewController(identifier: "Camera") as? CameraVC {
            vc.isTruePhoto = isTruePhoto
            
                vc.takeUrgent = { photo in
                    self.urgentPhoto.append(photo)
                    self.save()
                }
            
                vc.takeUsual = { photo in
                    self.usualPhoto.append(photo)
                    self.save()
                }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        if isTruePhoto {
            let urgent = UrgentPhoto(name: "Unknown", image: imageName)
            urgentPhoto.append(urgent)
            save()
            urgentCV.reloadData()
        } else {
            let usual = UsualPhoto(name: "Unknown", image: imageName)
            usualPhoto.append(usual)
            save()
            usualCV.reloadData()
        }
        dismiss(animated: true)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    //кнопка свойства для одавления/удаления фотографий в альбоме СРОЧНЫЕ
    @IBAction func buttonUrgent(_ sender: Any) {
        isTruePhoto = true
        let ac = UIAlertController(title: "Что сделать с альбомом?", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Добавить фото", style: .default, handler: addPhoto(action:)))
        if !urgentPhoto.isEmpty {
            ac.addAction(UIAlertAction(title: "Удалить все фото", style: .destructive) { [weak self] _ in
                let uac = UIAlertController(title: "Вы уверены?", message: nil, preferredStyle: .alert)
                uac.addAction(UIAlertAction(title: "Да", style: .default) { [weak self]_ in
                    self?.urgentPhoto.removeAll()
                    self?.save()
                    self?.urgentCV.reloadData()
                })
                uac.addAction(UIAlertAction(title: "Нет", style: .cancel))
                self?.present(uac, animated: true)
            })
        }
        present(ac, animated: true)
    }
    
    //кнопка свойства для одавления/удаления фотографий в альбоме ОБЫЧНЫЕ
    @IBAction func buttonUsual(_ sender: Any) {
        isTruePhoto = false
        let ac = UIAlertController(title: "Что сделать с альбомом?", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Добавить фото", style: .default, handler: addPhoto(action:)))
        if !usualPhoto.isEmpty {
            ac.addAction(UIAlertAction(title: "Удалить все фото", style: .destructive) { [weak self] _ in
                let uac = UIAlertController(title: "Вы уверены?", message: nil, preferredStyle: .alert)
                uac.addAction(UIAlertAction(title: "Да", style: .default) { [weak self]_ in
                    self?.usualPhoto.removeAll()
                    self?.save()
                    self?.usualCV.reloadData()
                })
                uac.addAction(UIAlertAction(title: "Нет", style: .cancel))
                self?.present(uac, animated: true)
            })
        }
        present(ac, animated: true)
    }
    
    //удаляем фото по долгому тапу
    @objc func longPressUrgent(longPressGesture : UILongPressGestureRecognizer) {
        let point = longPressGesture.location(in: urgentCV)
        let indexPath = self.urgentCV.indexPathForItem(at: point)
        
        if indexPath != nil
        {
            let ac = UIAlertController(title: "Что сделать с фото?", message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { [weak self] action in
                self?.urgentPhoto.remove(at: indexPath!.item)
                self?.save()
                self?.urgentCV.reloadData()
            }))
            ac.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(ac, animated: true)
        }
    }
    
    //удаляем фото по долгому тапу
    @objc func longPressUsual(longPressGesture : UILongPressGestureRecognizer) {
        
        let point = longPressGesture.location(in: usualCV)
        let indexPath = self.usualCV.indexPathForItem(at: point)
        
        if indexPath != nil
        {
            let ac = UIAlertController(title: "Что сделать с фото?", message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { [weak self] action in
                self?.usualPhoto.remove(at: indexPath!.item)
                self?.save()
                self?.usualCV.reloadData()
            }))
            ac.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(ac, animated: true)
            
        }
    }
    
    //сохраняем фотографии
    func save() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(urgentPhoto) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "urgent")
        } else {
            print("Не удалось сохранить.")
        }
        
        if let savedData = try? jsonEncoder.encode(usualPhoto) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "usual")
        } else {
            print("Не удалось сохранить.")
        }
    }
}

