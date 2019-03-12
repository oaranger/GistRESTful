//
//  JSONDecoder+ext.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/21/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import Foundation
import Alamofire

enum BackendError: Error {
    case network(error: Error)
    case unexpectedResponse(reason: String)
    case parsing(error: Error)
    case apiProvidedError(reason: String)
    case authCouldNot(reason: String)
    case authLost(reason: String)
    case missingRequiredInput(reason: String)
}

struct APIProvidedError: Codable {
    let message: String
}

extension JSONDecoder {
    
    func decodeResponse<T: Decodable>(from response: DataResponse<Data>) -> Result<T> {
        guard response.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.error!)
            return .failure(BackendError.network(error: response.error!))
        }
        
        // make sure we got JSON and it's a dictionary
        guard let responseData = response.data else {
            print("didn't get any data from API")
            return .failure(BackendError.unexpectedResponse(reason:
            "Did not get data in response"))
        }
        
        // check for "message" errors in the JSON because this API does that
        if let apiProvidedError = try? self.decode(APIProvidedError.self, from: responseData) {
            return .failure(BackendError.apiProvidedError(reason: apiProvidedError.message))
        }
        
        // turn data into expected type
        do {
            let item = try self.decode(T.self, from: responseData)
            return .success(item)
        } catch {
            print("error trying to decode response")
            print(error)
            return .failure(BackendError.parsing(error: error))
        }
    }
}
