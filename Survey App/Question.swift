//
//  Question.swift
//  Survey App
//
//  Created by Konstantinos Gouzinis on 5/4/24.
//

import Foundation

struct Question: Codable {
    let id: Int
    let question: String
}

struct Answer: Codable {
    let id: Int
    let answer: String
}

enum QuestionError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
