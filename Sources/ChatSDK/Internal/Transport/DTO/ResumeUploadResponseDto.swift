//
//  ResumeUploadResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.05.2026.
//

import Foundation


struct ResumeUploadResponseDto: Decodable {
    let uploadId: String
    let size: Int64

    enum CodingKeys: String, CodingKey {
        case uploadId
        case size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uploadId = try container.decode(String.self, forKey: .uploadId)
        
        if let intValue = try? container.decode(Int.self, forKey: .size) {
            size = Int64(intValue)
            
        } else if let int64Value = try? container.decode(Int64.self, forKey: .size) {
            size = int64Value
            
        } else if let stringValue = try? container.decode(String.self, forKey: .size),
                  let intValue = Int64(stringValue) {
            size = intValue
            
        } else {
            size = 0
        }
    }
}
