import Foundation

struct InterestItem: Hashable, Codable {
    let title: String
    let symbol: String

    /// Canonical list of all available interests – single source of truth.
    static let allItems: [InterestItem] = [
        InterestItem(title: "Technology",   symbol: "cpu"),
        InterestItem(title: "Gaming",       symbol: "gamecontroller.fill"),
        InterestItem(title: "Travel",       symbol: "airplane"),
        InterestItem(title: "Fitness",      symbol: "dumbbell"),
        InterestItem(title: "Food",         symbol: "fork.knife"),
        InterestItem(title: "Music",        symbol: "music.note.list"),
        InterestItem(title: "Movies",       symbol: "film.fill"),
        InterestItem(title: "Photography",  symbol: "camera.fill"),
        InterestItem(title: "Finance",      symbol: "chart.bar.xaxis"),
        InterestItem(title: "Business",     symbol: "briefcase.fill"),
        InterestItem(title: "Health",       symbol: "heart.fill"),
        InterestItem(title: "Learning",     symbol: "book.fill"),
        InterestItem(title: "Productivity", symbol: "checkmark.circle"),
        InterestItem(title: "Shopping",     symbol: "cart.fill"),
        InterestItem(title: "Sports",       symbol: "sportscourt.fill"),
        InterestItem(title: "Cars",         symbol: "car.fill"),
        InterestItem(title: "Cooking",      symbol: "takeoutbag.and.cup.and.straw.fill"),
        InterestItem(title: "Fashion",      symbol: "tshirt.fill"),
        InterestItem(title: "Pets",         symbol: "pawprint.fill"),
        InterestItem(title: "Art & Design", symbol: "paintpalette.fill")
    ]

    /// The first 6 popular interests shown on the onboarding intro screen.
    static let popularItems: [InterestItem] = Array(allItems.prefix(9))
}
