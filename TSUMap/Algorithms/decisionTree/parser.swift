import Foundation

func CSVParser(content: String) -> [TreeAttribute] {
    var attributes: [TreeAttribute] = []
    let rows = content.split(separator: "\n")

    for row in rows {
        let words = row.split(separator: ",")
        if words.count == 7 {
            let attribute = TreeAttribute(
                location: words[0].trimmingCharacters(in: .whitespaces),
                budget: words[1].trimmingCharacters(in: .whitespaces),
                time_available: words[2].trimmingCharacters(in: .whitespaces),
                food_type: words[3].trimmingCharacters(in: .whitespaces),
                queue_tolerance: words[4].trimmingCharacters(in: .whitespaces),
                weather: words[5].trimmingCharacters(in: .whitespaces),
                recommended_place: words[6].trimmingCharacters(in: .whitespaces)
            )
            attributes.append(attribute)
        }
    }
    return attributes
}
