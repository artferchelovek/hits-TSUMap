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
    
    let treeNode: TreeNode?
    
    var onPredictionCompleted: ((String) -> Void)?
    
    @State private var userAttribute = Attribute(
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
    
    let questions: [QuestionStep] = [
        QuestionStep(text: "Где вы сейчас находитесь?", options: [
            AnswerOption(title: "Главный корпус", value: "main_building"),
            AnswerOption(title: "Второй корпус", value: "second_building"),
            AnswerOption(title: "Остановка", value: "bus_stop"),
            AnswerOption(title: "Кампус Центр", value: "campus_center")
        ]),
        QuestionStep(text: "Сколько у вас денег?", options: [
            AnswerOption(title: "Немного", value: "low"),
            AnswerOption(title: "Средне", value: "medium"),
            AnswerOption(title: "Достаточно", value: "high")
        ]),
        QuestionStep(text: "Сколько у вас времени?", options: [
            AnswerOption(title: "Мало", value: "very_short"),
            AnswerOption(title: "Перемена", value: "short"),
            AnswerOption(title: "Пара", value: "medium")
        ]),
        QuestionStep(text: "Чего хочется?", options: [
            AnswerOption(title: "Кофе", value: "coffee"),
            AnswerOption(title: "Блинчики", value: "pancakes"),
            AnswerOption(title: "Перекус", value: "snack"),
            AnswerOption(title: "Плотный обед", value: "full_meal")
        ]),
        QuestionStep(text: "Готовы стоять в очереди?", options: [
            AnswerOption(title: "Нет", value: "low"),
            AnswerOption(title: "Средне", value: "medium"),
            AnswerOption(title: "Да", value: "high")
        ]),
        QuestionStep(text: "Как погода на улице?", options: [
            AnswerOption(title: "Хорошая", value: "good"),
            AnswerOption(title: "Плохая", value: "bad")
        ])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.secondary)
                            .padding(5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    
                    Spacer()
                    
                    Text("Куда сходить?")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        //
                    } label: {
                        Image(systemName: "document.badge.gearshape")
                            .foregroundColor(Color.white)
                            .padding(5)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 10)
            
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
                .onChange(of: messages.count) { _ in
                    if let lastId = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
            
            if !isFinished {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(questions[currentIndex].options) { option in
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
            } else {
                Button {
                    print("Итоговые данные: \(userAttribute)")
                    if let treeNode = treeNode {
                        let (result, _) = predict(tree: treeNode, situation: userAttribute)
                        print("Рекомендация: \(result)")
                        onPredictionCompleted?(result)
                    }
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
        }
        .onAppear {
            if messages.isEmpty {
                messages.append(ChatMessage(text: questions[0].text, isUser: false))
            }
        }
    }
    
    private func handleAnswer(option: AnswerOption) {
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
                let botMessage = ChatMessage(text: questions[currentIndex].text, isUser: false)
                withAnimation(.spring()) { messages.append(botMessage) }
            } else {
                withAnimation(.spring()) {
                    isFinished = true
                }
                
                if let treeNode = treeNode {
                    let (result, _) = predict(tree: treeNode, situation: userAttribute)
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
    DecisionTreeView(treeNode: nil)
}
