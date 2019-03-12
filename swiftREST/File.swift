//
//  File.swift
//  swiftREST
//
//  Created by Binh Huynh on 12/11/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import Foundation

struct File: Codable {
    enum CodingKeys: String, CodingKey {
        case url = "raw_url"
        case content
    }
    let url: URL?
    let content: String?
}
