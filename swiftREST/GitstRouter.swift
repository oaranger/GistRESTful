//
//  GitstRouter.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/21/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import Foundation
import Alamofire

enum GistRouter: URLRequestConvertible {
    static let baseURLString = "https://api.github.com/"
    case getPublic()
    case getMyStarred()
    case getAtPath(String)
    case getMine()
    case isStarred(String)
    case star(String)
    case unstar(String)
    case delete(String)
    case create(Data)
    
    func asURLRequest() throws -> URLRequest {
        var method: HTTPMethod {
            switch self {
            case .getPublic, .getAtPath, .getMyStarred, .getMine, .isStarred:
                return .get
            case .star:
                return .put
            case .unstar, .delete:
                return .delete
            case .create:
                return .post
            }
        }
        
        let url: URL = {
            let relativePath: String
            switch self {
            case .getPublic():
                relativePath = "gists/public"
            case .getAtPath(let path):
                return URL(string: path)!
            case .getMyStarred:
                relativePath = "gists/starred"
            case .getMine():
                relativePath = "gists"
            case .isStarred(let id):
                relativePath = "gists/\(id)/star"
            case .star(let id):
                relativePath = "gists/\(id)/star"
            case .unstar(let id):
                relativePath = "gists/\(id)/star"
            case .delete(let id):
                relativePath = "gists/\(id)"
            case .create:
                relativePath = "gists"
            }
            var url = URL(string: GistRouter.baseURLString)!
            url.appendPathComponent(relativePath)
            return url
        }()
        
        let body: Data? = {
            switch self {
            case .create(let jsonData):
                return jsonData
            default: return nil
            }
        }()
        
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body

        if let token = GitHubAPIManager.shared.OAuthToken {
            urlRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return urlRequest
    }
}
