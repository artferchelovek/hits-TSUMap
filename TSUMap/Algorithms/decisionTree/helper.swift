func getAttribute (from item: treeAttribute, for column: String) -> String {
    switch column {
    case "location": return item.location
    case "budget": return item.budget
    case "time_available": return item.time_available
    case "food_type": return item.food_type
    case "queue_tolerance": return item.queue_tolerance
    case "weather": return item.weather
    case "recommended_place": return item.recommended_place
    default: return ""
    }
}
