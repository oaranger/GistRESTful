//
//  PersistenceManager.swift
//  swiftREST
//
//  Created by Binh Huynh on 12/18/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import Foundation

class PersistenceManager {
    enum Path: String {
        case Public = "Public"
        case Starred = "Starred"
        case MyGists = "MyGists"
    }
    class private func cachesDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    class func save<T: Encodable>(_ itemToSave: T, path: Path) -> Bool {
        // TODO: implement
        guard let directory = cachesDirectory() else {
            print("Could not save - no caches directory")
            return false
        }
        let file = directory.appendingPathComponent(path.rawValue)
        print("Directory \(file)")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let itemAsData = try encoder.encode(itemToSave)
            //check for existing data
            if FileManager.default.fileExists(atPath: file.path) {
                print("removing file")
                try FileManager.default.removeItem(at: file)
            }
            // add the file
            FileManager.default.createFile(atPath: file.path, contents: itemAsData, attributes: nil)
        } catch {
            print(error)
            return false
        }
        return true
    }
    class func load<T: Decodable>(path: Path) -> T? {
        guard let directory = cachesDirectory() else {
            print("Could not load - no caches directory")
            return nil
        }
        let file = directory.appendingPathComponent(path.rawValue)
        if !FileManager.default.fileExists(atPath: file.path) {
            print("Could not load - no file at expected path")
            return nil
        }
        guard let itemAsData = FileManager.default.contents(atPath: directory.path) else {
            print("could not load - no data in file at expected path")
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let item = try decoder.decode(T.self, from: itemAsData)
            return item
        } catch {
            print(error)
            return nil
        }
    }
    
}


