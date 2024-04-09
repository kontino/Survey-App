//
//  SurveyViewModel.swift
//  Survey App
//
//  Created by Konstantinos Gouzinis on 5/4/24.
//

import Foundation
import SwiftUI

final class SurveyViewModel: ObservableObject {
    
    @Published var questions: [Question]?
    @Published var answers: [String]?
    @Published var questionIndex: Int = 1
    @Published var questionsSubmitted: Int = 0
    @Published var totalQuestions = 20
    @Published var submissionStatus: [Bool] = [false]
    @Published var questionDisplayed: String = "Question placeholder"
    @Published var isDataFetched: Bool = false
    @Published var showAlert = false
    @Published var bannerText = ""
    @Published var bannerColor = Color(.green)
    
    init() {
        fetchQuestions()
    }
    
    func fetchQuestions() {
        Task {
            do {
                let content = try await getQuestions()
                await MainActor.run {
                    questions = content
                    totalQuestions = questions?.count ?? 5
                    submissionStatus = [Bool](repeating: false, count: totalQuestions)
                    answers = [String](repeating: "", count: totalQuestions)
                    isDataFetched = true
                    updateQuestion()
                }
            } catch QuestionError.invalidData {
                print("Invalid data")
            } catch QuestionError.invalidResponse {
                print("Invalid response")
            } catch QuestionError.invalidURL {
                print("Invalid URL")
            } catch {
                print("Unexpected error")
            }
        }
    }
    
    func getQuestions() async throws -> [Question] {
        let endpoint = "https://xm-assignment.web.app/questions"
        
        guard let url = URL(string: endpoint) else {
            throw QuestionError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw QuestionError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedData = try decoder.decode([Question].self, from: data)
            return decodedData
        } catch {
            throw QuestionError.invalidData
        }
        
    }
    
    func submitAnswer(answer: String) {
        submitAnswer(id: questionIndex, answer: answer) { [weak self] statusCode in
            guard let self = self else { return }
            print("Received response with status: \(statusCode)")
            if statusCode == 200 {
                Task {
                    await MainActor.run {
                        self.submissionStatus[self.questionIndex-1] = true
                        self.answers?[self.questionIndex-1] = answer
                        self.questionsSubmitted += 1
                        self.bannerText = "Success"
                        withAnimation{self.showAlert = true}
                        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                            self.showAlert = false
                        }
                        self.bannerColor = Color(.green)
                    }
                }
            } else {
                Task {
                    await MainActor.run {
                        self.bannerText = "Failure"
                        withAnimation{self.showAlert = true}
                        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                            self.showAlert = false
                        }
                        self.bannerColor = Color(.red)
                    }
                }
            }
        }
    }
    
    private func submitAnswer(id: Int, answer: String, completion: @escaping (Int) -> Void) {
        let endpoint = "https://xm-assignment.web.app/question/submit"
        guard let url = URL(string: endpoint) else {
            print("Error: Invalid URL")
            return
        }
        // Create request from URL
        var request = URLRequest(url: url)
        
        // Structure the data in a json format
        let parameters: [String: Any] = [
            "id": id,
            "answer": answer
        ]
        
        // Try encoding the data to an object
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
        } catch {
            print("Error creating data object from json.")
            completion(0)
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Initiate URLSession
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, data != nil else {
                print("Error trying to submit answer: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
                // Handle response status code or data if needed
                completion(httpResponse.statusCode)
                
            }
        }.resume()
        
    }
    
    func getSubmitButtonText() -> String {
        if submissionStatus[questionIndex-1] == false {
            return "Submit"
        } else {
            return "Already submitted"
        }
    }
    
    func goToPreviousQuestion() {
        questionIndex -= 1
        updateQuestion()
    }
    
    func goToNextQuestion() {
        questionIndex += 1
        updateQuestion()
    }
    
    func isFirstQuestion() -> Bool {
        return questionIndex == 1
    }
    
    func isLastQuestion() -> Bool {
        return questionIndex == totalQuestions
    }
    
    func updateQuestion() {
        questionDisplayed = questions?[questionIndex-1].question ?? "Question placeholder"
    }
    
    func isAnswerSubmitted() -> Bool {
        return isDataFetched && submissionStatus[questionIndex-1]
    }
}
