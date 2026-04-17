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
    @ObservedObject var placeManager: PlaceManager
    @State private var session: TreeSession?
    @State private var selectedPlace: IdentifiableItem?

    let treeNode: TreeNode?

    @Binding var endLocation: GridPoint?

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
    @State private var isAnswering = false

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
                        .disabled(isAnswering)
                        .opacity(isAnswering ? 0.4 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isAnswering)
                } else {
                    finishButton
                }
            }

            .onAppear {
                if let tree = treeNode {
                    session = TreeSession(tree: tree)
                    if let firstQuestionAttr = session?.getNextQuestion() {
                        let firstMsg = ChatMessage(text: questions.first(where: { $0.key == firstQuestionAttr })?.chatText ?? "", isUser: false)
                        messages.append(firstMsg)
                    }
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
                        SettingsDecisionTreeView(manager: manager, placeManager: placeManager)
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
                if let currentAttr = session?.getNextQuestion(),
                   let currentQuestion = AppConfig.questions.first(where: { $0.key == currentAttr })
                {
                    ForEach(currentQuestion.options) { option in
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
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var finishButton: some View {
        Button {
            endLocation = selectedPlace?.item.entryCord
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
        isAnswering = true
        let userMessage = ChatMessage(text: option.title, isUser: true)
        withAnimation(.spring()) { messages.append(userMessage) }
        session?.provideAnswer(answer: option.value)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) { isAnswering = false }

            if let result = session?.getFinalResult() {
                withAnimation(.spring()) {
                    isFinished = true

                    let components = result.components(separatedBy: "@")
                    let name = components[0]

                    messages.append(ChatMessage(text: "Рекомендую посетить:", isUser: false))
                    messages.append(ChatMessage(text: name, isUser: false))

                    if components.count > 1,
                       let parseResult = placeManager.getPlaceById(components[1])
                    {
                        selectedPlace = parseResult
                    }
                }
            } else if let nextAttribute = session?.getNextQuestion() {
                if let nextQuestions = AppConfig.questions.first(where: { $0.key == nextAttribute }) {
                    let botMessage = ChatMessage(text: nextQuestions.chatText, isUser: false)
                    withAnimation(.spring()) { messages.append(botMessage) }
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
    DecisionTreeView(
        manager: VenueManager(),
        placeManager: PlaceManager(),
        treeNode: buildTree(data: VenueManager().allAttributes, availableAttributes: AppConfig.aviableTreeAttributes),
        endLocation: .constant(nil as GridPoint?)
    )
}
