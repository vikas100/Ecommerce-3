//
//  APIController.swift
//  Ecommerce
//
//  Created by Neethu Sadasivan on 13/11/17.
//  Copyright © 2017 Neethu Sadasivan. All rights reserved.
//

import Foundation

protocol APIControllerProtocol {
    func didReceiveAPIResults(_ results: Dictionary<String, Any>)
}

class APIController {
    
    var delegate: APIControllerProtocol? = nil
    
    init(){
        
    }

    func fetchJSONData(urlString: String) {
        
        if Reachability.isConnectedToNetwork() == true {
            
            let urlString = URL(string: urlString)
            //if let url = urlString {
            let task = URLSession.shared.dataTask(with: urlString!) { (data, response, error) in
                if error != nil {
                    print(error as Any)
                } else {
                    if let usableData = data {
                        do {
                            if let result = try JSONSerialization.jsonObject(with: usableData, options: []) as? Dictionary<String, Any> {
                                let jsonData = ["json_data": result]
                                self.delegate?.didReceiveAPIResults(jsonData)
                            }
                        } catch let error as NSError {
                            let jsonError = ["error": error.localizedDescription]
                            self.delegate?.didReceiveAPIResults(jsonError)
                        }
                    }
                }
            }
            task.resume()
            
        }
        else {
            print("No internet Connection")
            let jsonError = ["error": "Please check your internet connection."]
            self.delegate?.didReceiveAPIResults(jsonError)
        }
    }
    
}
