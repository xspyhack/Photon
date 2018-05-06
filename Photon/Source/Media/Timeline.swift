//
//  Timeline.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import CoreMedia

public protocol Timeline {
    
    var timeRange: CMTimeRange { get set }
    
    var startTime: CMTime { get set }
}
