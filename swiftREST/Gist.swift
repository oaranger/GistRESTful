//
//  Gist.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/21/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import Foundation

struct Gist: Codable {
    
    struct Owner: Codable {
        var login: String
        var avatarURL: URL?
        
        enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }
    
    var id: String?
    var gistDescription: String?
    var url: URL?
    var owner: Owner?
    let createdAt: Date?
    let updatedAt: Date?
    let files: [String: File]
    let isPublic: Bool
    lazy var orderedFiles: [(name: String, details: File)] = {
        var orderedFiles: [(name: String, details: File)] = []
        for (key, value) in files {
            let item = (name: key, details: value)
            orderedFiles.append(item)
        }
        return orderedFiles
    }()
    
    enum CodingKeys: String, CodingKey {
        case id
        case gistDescription = "description"
        case url
        case owner
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case files
        case isPublic = "public"
    }
    
    init(gistDescription: String, files: [String: File], isPublic: Bool) {
        self.gistDescription = gistDescription
        self.files = files
        self.isPublic = isPublic
        self.id = nil
        self.url = nil
        self.owner = nil
        self.createdAt = nil
        self.updatedAt = nil
    }
}
