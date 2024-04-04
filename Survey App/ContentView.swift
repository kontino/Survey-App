//
//  ContentView.swift
//  Survey App
//
//  Created by Konstantinos Gouzinis on 3/4/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            VStack {
                Text("Welcome to the Survey App!")
                    .font(.system(size:24))
                NavigationLink(destination: ScreenTwo()) {
                    Text("Start Survey")
                        
                }
                .buttonStyle(.bordered)
//                .navigationTitle("Initial Screen")
                .padding(8.0)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Define Screen Two
struct ScreenTwo: View {
//    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var questions: [Question]?
    @State private var textInput: String = ""
    @State private var questionIndex: Int = 1
    @State private var questionsSubmitted: Int = 0
    @State private var totalQuestions = 20
    @State private var submissionStatus: [Bool] = [false]
    @State private var questionDisplayed: String = "Question placeholder"
    @State private var isDataFetched: Bool = false
    @State private var showAlert = false
    @State private var bannerText = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            
            VStack(alignment: .leading) {
                Text("Questions submitted: \(questionsSubmitted)")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 24))
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                VStack{
                    Text("\(questionDisplayed)")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 24))
                        .padding(8)
                        .multilineTextAlignment(.leading)
                    
                    TextField("Type answer here.", text: $textInput, onCommit: {
                            print("You answered: \(textInput)")
                            submitAnswer(id: questionIndex, answer: textInput) { statusCode in
                            print("Received response with status: \(statusCode)")
                            if statusCode == 200 {
                                submissionStatus[questionIndex-1] = true
                                questionsSubmitted += 1
                                bannerText = "Success"
                                showAlert = true
                            } else {
                                bannerText = "Failure"
                                showAlert = true
                            }
                            textInput = ""
                        }
                    })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray)
                        .cornerRadius(8.0)
                    
                    Button("Submit") {
                        print("You answered: \(textInput)")
                        submitAnswer(id: questionIndex, answer: textInput) { statusCode in
                            print("Received response with status: \(statusCode)")
                            if statusCode == 200 {
                                submissionStatus[questionIndex-1] = true
                                questionsSubmitted += 1
                            }
                        textInput = ""
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDataFetched && submissionStatus[questionIndex-1] == true)
                }
                .padding()
                
                
                Spacer()
                
            }
            .padding(.top)
            
        }
        .alert(isPresented: $showAlert) {
                    Alert(title: Text("Message"), message: Text(bannerText), dismissButton: .default(Text("OK")))
                }
//        .navigationTitle("Screen Two")
//        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading:
                HStack{
                    Spacer(minLength: 8)
                    Text("Question \(questionIndex)/\(totalQuestions)")
                },
            trailing:
                HStack{
                    Spacer(minLength: 8)
                    Button("Previous") {
                        questionIndex -= 1
                        updateQuestion()
                    }
                    .disabled(questionIndex == 1)
                    Spacer(minLength: 16)
                    Button("Next") {
                        questionIndex += 1
                        updateQuestion()
                    }
                    .disabled(questionIndex == totalQuestions)
                    Spacer(minLength: 8)
                }
        )
        .task {
            do {
                questions = try await getQuestions()
                totalQuestions = questions?.count ?? 5
                submissionStatus = [Bool](repeating: false, count: totalQuestions)
                isDataFetched = true
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
    
    func submitAnswer(id: Int, answer: String, completion: @escaping (Int) -> Void) {
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
    
    func updateQuestion() {
        questionDisplayed = questions?[questionIndex-1].question ?? "Question placeholder"
    }
}

struct CustomBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .foregroundColor(.blue)
        }
    }
}

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
