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
                NavigationLink(destination: SurveyView()) {
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
struct SurveyView: View {

    @StateObject private var surveyVM = SurveyViewModel()
    @State private var textInput: String = ""
    @State private var showBanner: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                
                if surveyVM.showAlert {
                    Spacer()
                    ZStack(alignment: .center){
                    
                        RoundedRectangle(cornerRadius: 15)
                            .fill(surveyVM.bannerColor)
                            .frame(
                                width: UIScreen.main.bounds.width * 0.9,
                                height: UIScreen.main.bounds.height * 0.1
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom),
                                removal: .move(edge: .bottom)
                            ))

                        HStack {

                            Text(surveyVM.bannerText)
                                .padding()
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .transition(.move(edge: .bottom))
                            if surveyVM.bannerText == "Failure" {
                                Button("Retry"){
                                    surveyVM.showAlert.toggle()
                                }
                                .padding()
                                .foregroundColor(.black)
                                .background(Color.white)
                                .cornerRadius(8)
                                .transition(.move(edge: .bottom))
                            }
                        }
                        
                    }
                  
                }
                
            }
            VStack(alignment: .leading) {
                Text("Questions submitted: \(surveyVM.questionsSubmitted)")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 24))
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                VStack{
                    Text("\(surveyVM.questionDisplayed)")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 24))
                        .padding(8)
                        .multilineTextAlignment(.leading)
                    
                    if !surveyVM.isAnswerSubmitted() {
                        TextField("Type answer here.", text: $textInput, onCommit: {
                            print("You answered: \(textInput)")
                            surveyVM.submitAnswer(answer: textInput)
                            textInput = ""
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray)
                        .cornerRadius(8.0)
                    } else {
                        Text(surveyVM.answers?[surveyVM.questionIndex-1] ?? "")
                    }

                    Button(surveyVM.getSubmitButtonText()) {
                        print("You answered: \(textInput)")
                        surveyVM.submitAnswer(answer: textInput)
                        textInput = ""
                    }
                    .buttonStyle(.bordered)
                    .disabled(surveyVM.isAnswerSubmitted())
                }
                .padding()
                
                Spacer()
            }
            .padding(.top)
    
        }
//        .alert(isPresented: $surveyVM.showAlert) {
//            Alert(title: Text("Message"), message: Text(surveyVM.bannerText), dismissButton: .default(Text("OK")))
//        }
        .navigationBarItems(
            leading:
                HStack{
                    Spacer(minLength: 8)
                    Text("Question \(surveyVM.questionIndex)/\(surveyVM.totalQuestions)")
                },
            trailing:
                HStack{
                    Spacer(minLength: 8)
                    Button("Previous") {
                        surveyVM.goToPreviousQuestion()
                        textInput = ""
                    }
                    .disabled(surveyVM.isFirstQuestion())
                    Spacer(minLength: 16)
                    Button("Next") {
                        surveyVM.goToNextQuestion()
                        textInput = ""
                    }
                    .disabled(surveyVM.isLastQuestion())
                    Spacer(minLength: 8)
                }
        )

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
