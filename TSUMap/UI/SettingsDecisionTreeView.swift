//
//  SettingsDecisionTreeView.swift
//  TSUMap
//
//  Created by Artem on 24.03.2026.
//

import SwiftUI

struct IdentifiablePlace: Identifiable {
    let id: String
}

struct SettingsDecisionTreeView: View {
    @ObservedObject var manager: VenueManager
    @State private var activePlace: IdentifiablePlace?
    
    var body: some View {
        NavigationView {
            List {
                let grouped = manager.groupedAttributes
                
                ForEach(grouped.keys.sorted(), id: \.self) { name in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(name.replacingOccurrences(of: "_", with: " "))
                                .font(.headline)
                            Text("Сценариев: \(grouped[name]?.count ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activePlace = IdentifiablePlace(id: name)
                    }
                }
                .onDelete { indexSet in
                    let keys = grouped.keys.sorted()
                    for index in indexSet {
                        manager.removeAllEntries(named: keys[index])
                    }
                }
            }
            
            .navigationTitle("Настроить предпочтения")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        manager.resetToDefaults()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activePlace = IdentifiablePlace(id: "NEW_VENUE")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activePlace) { place in
                EditVenueView(
                    manager: manager,
                    venueName: place.id == "NEW_VENUE" ? nil : place.id
                )
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct EditVenueView: View {
    @ObservedObject var manager: VenueManager
    @Environment(\.dismiss) var dismiss
    
    var venueName: String?
    
    @State private var placeName = ""
    @State private var selections: [String: Set<String>] = [:]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ИНФОРМАЦИЯ О ЗАВЕДЕНИИ")) {
                    TextField("Название (например, Абрикос)", text: $placeName)
                        .disabled(venueName != nil)
                }
                
                ForEach(AppConfig.questions) { question in
                    makeMultiSelectSection(
                        title: question.title,
                        options: question.options,
                        key: question.key,
                        color: .blue
                    )
                }
            }
            .navigationTitle(venueName == nil ? "Новое место" : "Настройка")
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { saveComplexAction() }
                        .disabled(isSaveDisabled)
                }
            }
            .onAppear { loadExistingData() }
        }
    }
    
    private var isSaveDisabled: Bool {
        let allSectionsSelected = AppConfig.questions.allSatisfy { q in
                !(selections[q.key]?.isEmpty ?? true)
            }
        return placeName.isEmpty || !allSectionsSelected
    }
    
    private func makeMultiSelectSection(title: String, options: [QuestionConfig.Option], key: String, color: Color) -> some View {
        Section(header: Text(title)) {
            ForEach(options) { option in
                Button(action: {
                    if selections[key] == nil { selections[key] = [] }
                    
                    if selections[key]!.contains(option.value) {
                        selections[key]!.remove(option.value)
                    } else {
                        selections[key]!.insert(option.value)
                    }
                }, label: {
                    HStack {
                        Text(option.title)
                            .foregroundColor(.primary)
                        Spacer()
                        if selections[key]?.contains(option.value) ?? false {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(color)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }
                })
            }
        }
    }
    
    private func loadExistingData() {
        guard let name = venueName else { return }
        placeName = name
        let rows = manager.allAttributes.filter { $0.recommended_place == name }
        
        for question in AppConfig.questions {
            let values = rows.map { row in
                switch question.key {
                case "location": return row.location
                case "budget": return row.budget
                case "time_available": return row.time_available
                case "food_type": return row.food_type
                case "queue_tolerance": return row.queue_tolerance
                case "weather": return row.weather
                default: return ""
                }
            }
            selections[question.key] = Set(values)
        }
    }
    
    private func saveComplexAction() {
        if let name = venueName {
            manager.removeAllEntries(named: name)
        }
        
        let locs = selections["location"] ?? []
        let buds = selections["budget"] ?? []
        let times = selections["time_available"] ?? []
        let foods = selections["food_type"] ?? []
        let queues = selections["queue_tolerance"] ?? []
        let weathers = selections["weather"] ?? []
        
        var newEntries: [Attribute] = []
        
        for loc in locs {
            for bud in buds {
                for tim in times {
                    for food in foods {
                        for weath in weathers {
                            for queue in queues {
                                let newAttr = Attribute(
                                    location: loc,
                                    budget: bud,
                                    time_available: tim,
                                    food_type: food,
                                    queue_tolerance: queue,
                                    weather: weath,
                                    recommended_place: placeName
                                )
                                newEntries.append(newAttr)
                            }
                        }
                    }
                }
            }
        }
        
        manager.allAttributes.append(contentsOf: newEntries)
        manager.save()
        dismiss()
    }
}

#Preview {
    SettingsDecisionTreeView(manager: VenueManager())
}
