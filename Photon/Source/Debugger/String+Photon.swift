//
//  String+Photon.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 18/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

extension String : PhotonCompatible {
}

extension Photon where Base == String {
    
    func drawVerticallyCentered(in rect: CGRect, withAttributes attributes: [NSAttributedStringKey: Any]?) {
        
        let size = base.size(withAttributes: attributes)
        var drawRect = rect
        drawRect.origin.y += (rect.size.height - size.height) / 2.0
        
        base.draw(in: drawRect)
    }
}
