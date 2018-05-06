//
//  Layer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 02/12/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

public struct Layer : LayerProtocol {
    
    public var layer: CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
        layer.backgroundColor = UIColor.red.cgColor
        return layer
    }
}
