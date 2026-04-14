//
//  AppConfig.swift
//  TSUMap
//
//  Created by Artem on 30.03.2026.
//

import Foundation

struct QuestionConfig: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let chatText: String
    let options: [Option]

    struct Option: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }
}

enum AppConfig {
    static let cellScale = 4.5

    static let aviableTreeAttributes = [
        "location",
        "budget",
        "time_available",
        "food_type",
        "queue_tolerance",
        "weather",
    ]

    static let questions: [QuestionConfig] = [
        QuestionConfig(
            key: "location",
            title: "ВАШЕ МЕСТОПОЛОЖЕНИЕ",
            chatText: "Где вы сейчас находитесь?",
            options: [
                .init(title: "Главный корпус", value: "main_building"),
                .init(title: "Второй корпус", value: "second_building"),
                .init(title: "Остановка", value: "bus_stop"),
                .init(title: "Кампус Центр", value: "campus"),
            ]
        ),
        QuestionConfig(
            key: "budget",
            title: "БЮДЖЕТ",
            chatText: "Сколько у вас денег?",
            options: [
                .init(title: "Немного", value: "low"),
                .init(title: "Средне", value: "medium"),
                .init(title: "Достаточно", value: "high"),
            ]
        ),
        QuestionConfig(
            key: "time_available",
            title: "ЗАПАС ВРЕМЕНИ",
            chatText: "Сколько у вас времени?",
            options: [
                .init(title: "15 мин", value: "very_short"),
                .init(title: "30-50 мин", value: "short"),
                .init(title: "1-1.5 часа", value: "medium"),
                .init(title: ">1.5 часов", value: "long"),
            ]
        ),
        QuestionConfig(
            key: "food_type",
            title: "ЖЕЛАЕМАЯ ЕДА",
            chatText: "Чего хочется?",
            options: [
                .init(title: "Кофе", value: "coffee"),
                .init(title: "Блинчики", value: "pancakes"),
                .init(title: "Перекус", value: "snack"),
                .init(title: "Обед", value: "full_meal"),
            ]
        ),
        QuestionConfig(
            key: "queue_tolerance",
            title: "ОЧЕРЕДЬ",
            chatText: "Готовы стоять в очереди?",
            options: [
                .init(title: "Нет", value: "low"),
                .init(title: "Средне", value: "medium"),
                .init(title: "Да", value: "high"),
            ]
        ),
        QuestionConfig(
            key: "weather",
            title: "ПОГОДА",
            chatText: "Как погода на улице?",
            options: [
                .init(title: "Хорошая", value: "good"),
                .init(title: "Плохая", value: "bad"),
            ]
        ),
    ]
}
