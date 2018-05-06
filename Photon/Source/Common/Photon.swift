//
//  Photon.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 06/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

public struct Photon<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol PhotonCompatible {
    associatedtype BaseType
    
    var ph: Photon<BaseType> { get }
    static var ph: Photon<BaseType>.Type { get }
}

public extension PhotonCompatible {
    
    public var ph: Photon<Self> {
        return Photon(self)
    }
    
    public static var ph: Photon<Self>.Type {
        return Photon<Self>.self
    }
}

extension NSObject : PhotonCompatible {}
