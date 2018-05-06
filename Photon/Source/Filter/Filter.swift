//
//  Filter.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 12/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

public enum FilterType : String {
    case none
    case mono
    case tonal
    case noir
    case fade
    case chrome
    case process
    case transfer
    case instant
    
    var ciFilter: CIFilter? {
        return CIFilter(name: "CIPhotoEffect" + rawValue.capitalized)
    }
    
    static var all: [FilterType] {
        return [
            none,
            mono,
            tonal,
            noir,
            fade,
            chrome,
            process,
            transfer,
            instant,
        ]
    }
}

public struct Filter : FilterProtocol {
    
    let type: FilterType
    
    public init(type: FilterType) {
        self.type = type
    }
    
    public var filter: CIFilter {
        return type.ciFilter!
    }
}

