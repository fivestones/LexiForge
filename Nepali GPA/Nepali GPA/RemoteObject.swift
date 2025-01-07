//
//  RemoteObject.swift
//  Nepali GPA
//
//  Created by David Thomas on 1/7/25.
//

struct RemoteObject: Codable, Identifiable {
    let id: String
    let name: String
    let nepaliName: String
    let imageName: String?
    let videoName: String?
    let thisIsAudioFileName: String
    let negativeAudioFileName: String
    let whereIsAudioFileName: String
    let categories: [String]
    let sets: [String]
}
