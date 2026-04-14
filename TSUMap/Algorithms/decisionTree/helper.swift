func getTreeAttribute(from item: TreeAttribute, for column: String) -> String {
    switch column {
    case "location": item.location
    case "budget": item.budget
    case "time_available": item.time_available
    case "food_type": item.food_type
    case "queue_tolerance": item.queue_tolerance
    case "weather": item.weather
    case "recommended_place": item.recommended_place
    default: ""
    }
}
