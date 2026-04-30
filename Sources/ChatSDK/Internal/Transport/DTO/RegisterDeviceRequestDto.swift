//
//  RegisterDeviceRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation


internal struct RegisterDeviceRequestDto: Encodable {
    let fcm: String?
    let apn: String?
    
    init(fcm: String? = nil, apn: String? = nil) {
        self.fcm = fcm
        self.apn = apn
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(fcm, forKey: .fcm)
        try container.encodeIfPresent(apn, forKey: .apn)
    }
    
    enum CodingKeys: String, CodingKey {
        case fcm, apn
    }
}
