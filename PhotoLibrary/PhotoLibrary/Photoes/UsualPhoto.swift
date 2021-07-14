//
//  UsualPhoto.swift
//  PhotoLibrary
//
//  Created by Pavlov Matthew on 12.04.2021.
//

import UIKit

class UsualPhoto: NSObject, Codable {
    var name : String
    var image: String
    
    init (name: String, image: String) {
        self.name = name
        self.image = image
    }
}
