//
//  APIService.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import SwiftMessages

class APIService {


    
    static func getRandomAnonymousInfo(completion: @escaping (_ anonObject:AnonObject?, _ success:Bool)->()) {
        var anonObject:AnonObject?
        Auth.auth().currentUser!.getIDToken() { token, error in
            
            
            if error != nil {
                print(error?.localizedDescription)
                
                return completion(anonObject, false)
            }
            
            guard let tokenID = token else {
                return completion(anonObject, false)
            }
            
            print("TOKEN: \(tokenID)")
            let url = URL(string: "https://us-central1-jungleiosapp.cloudfunctions.net/app/randomAnonymousName")
            
            
            var request = URLRequest(url: url!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(tokenID)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard let data = data, error == nil else { return completion(anonObject, false) }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                        // Parse JSON
                        guard let adjective = json["adjective"] as? String else { return }
                        guard let animal = json["animal"] as? String else { return }
                        guard let color = json["color"] as? String else { return }
                        
                        anonObject = AnonObject(adjective: adjective, animal: animal, colorHexcode: color)
                        return completion(anonObject, true)
                    }
                } catch let parseError {
                    print("parsing error: \(parseError)")
                    return completion(anonObject, false)
                }
            }
            
            task.resume()
        }
        
    }
}
