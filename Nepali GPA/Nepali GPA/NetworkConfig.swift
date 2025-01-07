//
//  NetworkConfig.swift.swift
//  Nepali GPA
//
//  Created by David Thomas on 1/7/25.
//

import Foundation

class NetworkConfig: ObservableObject {
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
        }
    }
    
    init() {
        let defaultURL = "http://kepler.local:3000"
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? defaultURL
    }
    
    func getValidURL(_ path: String = "") -> URL? {
        var urlString = serverURL
        
        // Force HTTP
        urlString = urlString.replacingOccurrences(of: "https://", with: "http://", options: .caseInsensitive)
        if !urlString.lowercased().hasPrefix("http://") {
            urlString = "http://" + urlString
        }
        
        // Remove trailing slash if it exists
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        
        // Append the path if provided
        if !path.isEmpty {
            urlString = urlString + "/" + path
        }
        
        print("Final URL string: \(urlString)")
        return URL(string: urlString)
    }
}
