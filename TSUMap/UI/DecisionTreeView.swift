//
//  DecisionTreeView.swift
//  TSUMap
//
//  Created by Artem on 23.03.2026.
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct AnswerOption: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct QuestionStep {
    let text: String
    let options: [AnswerOption]
}

struct DecisionTreeView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var manager: VenueManager
    
    let treeNode: TreeNode?
    
    var onPredictionCompleted: ((String) -> Void)?
    
    @State private var isShowingSettingsSheet = false
    @State private var userAttribute = TreeAttribute(
        location: "",
        budget: "",
        time_available: "",
        food_type: "",
        queue_tolerance: "",
        weather: "",
        recommended_place: ""
    )
    @State private var currentIndex = 0
    @State private var messages: [ChatMessage] = []
    @State private var isFinished = false
    
    let questions = AppConfig.questions
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: messages.count) {
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if !isFinished {
                    answerOptionsPicker
                } else {
                    finishButton
                }
            }
            
            .onAppear {
                if messages.isEmpty {
                    messages.append(ChatMessage(text: questions[0].chatText, isUser: false))
                }
            }
            .navigationTitle("Куда сходить?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSettingsSheet.toggle()
                    } label: {
                        Image(systemName: "document.badge.gearshape")
                    }
                    .sheet(isPresented: $isShowingSettingsSheet) {
                        SettingsDecisionTreeView(manager: manager)
                            .presentationDragIndicator(.visible)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var answerOptionsPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AppConfig.questions[currentIndex].options) { option in
                    Button {
                        handleAnswer(option: option)
                    } label: {
                        Text(option.title)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var finishButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Показать маршрут")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
        }
        .padding()
    }
    
    private func handleAnswer(option: QuestionConfig.Option) {
        let userMessage = ChatMessage(text: option.title, isUser: true)
        withAnimation(.spring()) { messages.append(userMessage) }
        
        switch currentIndex {
        case 0: userAttribute.location = option.value
        case 1: userAttribute.budget = option.value
        case 2: userAttribute.time_available = option.value
        case 3: userAttribute.food_type = option.value
        case 4: userAttribute.queue_tolerance = option.value
        case 5: userAttribute.weather = option.value
        default: break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if currentIndex < questions.count - 1 {
                currentIndex += 1
                let botMessage = ChatMessage(text: questions[currentIndex].chatText, isUser: false)
                withAnimation(.spring()) { messages.append(botMessage) }
            } else {
                withAnimation(.spring()) {
                    isFinished = true
                }
                
                if let treeNode = treeNode {
                    let (result, _) = predictTree(tree: treeNode, situation: userAttribute)
                    withAnimation(.spring()) {
                        messages.append(ChatMessage(text: "Рекомендую посетить:", isUser: false))
                        messages.append(ChatMessage(text: "\(result)", isUser: false))
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue : Color(UIColor.systemGray6))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    DecisionTreeView(manager: VenueManager(), treeNode: nil)
}
