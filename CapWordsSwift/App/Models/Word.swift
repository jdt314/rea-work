import Foundation
import SwiftData

enum LearningLanguage: String, Codable, CaseIterable, Identifiable {
    case chinese = "zh-CN", cantonese = "zh-HK", english = "en-US", britishEnglish = "en-GB"
    case french = "fr-FR", spanish = "es-ES", japanese = "ja-JP", korean = "ko-KR", german = "de-DE", italian = "it-IT"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .chinese: "中文"
        case .cantonese: "中文（粤语）"
        case .english: "英语"
        case .britishEnglish: "英语（英式）"
        case .japanese: "日语"
        case .korean: "韩语"
        case .spanish: "西班牙语"
        case .french: "法语"
        case .german: "德语"
        case .italian: "意大利语"
        }
    }
    var flag: String {
        switch self {
        case .chinese, .cantonese: "🇨🇳"
        case .english: "🇺🇸"
        case .britishEnglish: "🇬🇧"
        case .french: "🇫🇷"
        case .spanish: "🇪🇸"
        case .japanese: "🇯🇵"
        case .korean: "🇰🇷"
        case .german: "🇩🇪"
        case .italian: "🇮🇹"
        }
    }

    var voiceSample: String {
        switch self {
        case .chinese: "你好，一起用单词探索世界吧。"
        case .cantonese: "你好，一齊用單詞探索世界啦。"
        case .english, .britishEnglish: "Hello! Let's discover the world, one word at a time."
        case .french: "Bonjour ! Découvrons le monde, un mot à la fois."
        case .spanish: "¡Hola! Descubramos el mundo, una palabra a la vez."
        case .japanese: "こんにちは。一緒に言葉の世界を探検しましょう。"
        case .korean: "안녕하세요. 함께 단어의 세계를 탐험해요."
        case .german: "Hallo! Entdecken wir die Welt, ein Wort nach dem anderen."
        case .italian: "Ciao! Scopriamo il mondo, una parola alla volta."
        }
    }
}

@Model
final class Word {
    @Attribute(.unique) var id: UUID
    var name: String
    var meaning: String
    var pronunciation: String
    var example: String
    var exampleMeaning: String
    var category: String
    var languageCode: String
    var createdAt: Date
    var nextReviewAt: Date
    var reviewStage: Int
    var reviewCount: Int
    var lastReviewAt: Date? = nil
    var isMastered: Bool = false
    var assetName: String?
    var isScene: Bool
    @Attribute(.externalStorage) var imageData: Data?

    init(name: String, meaning: String, pronunciation: String = "", example: String = "",
         exampleMeaning: String = "", category: String = "日常", languageCode: String = "en-US",
         createdAt: Date = .now, assetName: String? = nil, imageData: Data? = nil, isScene: Bool = false) {
        self.id = UUID()
        self.name = name
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.example = example
        self.exampleMeaning = exampleMeaning
        self.category = category
        self.languageCode = languageCode
        self.createdAt = createdAt
        self.nextReviewAt = createdAt
        self.reviewStage = 0
        self.reviewCount = 0
        self.assetName = assetName
        self.imageData = imageData
        self.isScene = isScene
    }
}

enum ReviewSchedule {
    // cap.ipa 0x100027434：阶段4进入长期掌握，不再安排到期日期。
    static let days = [1, 2, 4]
    static func next(stage: Int, remembered: Bool, now: Date = .now) -> (stage: Int, date: Date) {
        let nextStage = remembered ? min(max(stage, 0), 3) + 1 : 1
        guard nextStage < 4 else { return (4, .distantFuture) }
        return (nextStage, Calendar.current.date(byAdding: .day, value: days[nextStage - 1], to: now)!)
    }
}

@Model
final class ReviewRecord {
    @Attribute(.unique) var day: Date
    var wordIDs: [UUID]
    var knownIDs: [UUID]
    var unknownIDs: [UUID]

    init(date: Date, wordIDs: [UUID], knownIDs: [UUID], unknownIDs: [UUID]) {
        day = Calendar.current.startOfDay(for: date)
        self.wordIDs = wordIDs
        self.knownIDs = knownIDs
        self.unknownIDs = unknownIDs
    }
}

enum ReviewQueue {
    static func make(words: [Word], newLimit: Int = 5, now: Date = .now) -> [Word] {
        let due = words.filter { $0.reviewCount > 0 && !$0.isMastered && $0.reviewStage < 4 && $0.nextReviewAt <= now }
            .sorted { $0.nextReviewAt < $1.nextReviewAt }
        let fresh = words.filter { $0.reviewCount == 0 }.sorted { $0.createdAt < $1.createdAt }
        return due + fresh.prefix(max(0, newLimit))
    }
}

struct VocabularyEntry: Sendable {
    let key: String
    let english: String
    let meaning: String
    let pronunciation: String
    let category: String
    let example: String
    let exampleMeaning: String
    let translations: [LearningLanguage: String]

    func name(in language: LearningLanguage) -> String? {
        switch language {
        case .english, .britishEnglish: english
        case .chinese, .cantonese: meaning
        default: translations[language]
        }
    }
}

enum Vocabulary {
    static let entries: [VocabularyEntry] = [
        .init(key: "donut", english: "Donut", meaning: "甜甜圈", pronunciation: "/ˈdoʊnʌt/", category: "食物", example: "I picked a pink donut for breakfast.", exampleMeaning: "我挑了一个粉色甜甜圈当早餐。", translations: [.japanese: "ドーナツ", .korean: "도넛", .spanish: "Dónut", .french: "Beignet"]),
        .init(key: "toast", english: "Toast", meaning: "吐司", pronunciation: "/toʊst/", category: "食物", example: "Would you like some toast?", exampleMeaning: "你想来点吐司吗？", translations: [.japanese: "トースト", .korean: "토스트", .spanish: "Tostada", .french: "Pain grillé"]),
        .init(key: "bread", english: "Bread", meaning: "面包", pronunciation: "/bred/", category: "食物", example: "The bread is fresh from the bakery.", exampleMeaning: "面包是面包店刚出炉的。", translations: [.japanese: "パン", .korean: "빵", .spanish: "Pan", .french: "Pain"]),
        .init(key: "cup", english: "Cup", meaning: "杯子", pronunciation: "/kʌp/", category: "日常", example: "There is warm milk in my cup.", exampleMeaning: "我的杯子里有温牛奶。", translations: [.japanese: "カップ", .korean: "컵", .spanish: "Taza", .french: "Tasse"]),
        .init(key: "monstera", english: "Monstera", meaning: "龟背竹", pronunciation: "/mɒnˈsterə/", category: "自然", example: "My monstera grows beside the window.", exampleMeaning: "我的龟背竹长在窗边。", translations: [.japanese: "モンステラ", .korean: "몬스테라", .spanish: "Costilla de Adán", .french: "Monstera"]),
        .init(key: "tape", english: "Tape", meaning: "胶带", pronunciation: "/teɪp/", category: "日常", example: "Use some tape to wrap the gift.", exampleMeaning: "用一些胶带包装礼物。", translations: [.japanese: "テープ", .korean: "테이프", .spanish: "Cinta adhesiva", .french: "Ruban adhésif"]),
        .init(key: "clip", english: "Binder clip", meaning: "长尾夹", pronunciation: "/ˈbaɪndər klɪp/", category: "日常", example: "Keep the papers together with a binder clip.", exampleMeaning: "用长尾夹把纸夹在一起。", translations: [.japanese: "クリップ", .korean: "바인더 클립", .spanish: "Pinza", .french: "Pince-notes"]),
        .init(key: "switch", english: "Switch", meaning: "开关", pronunciation: "/swɪtʃ/", category: "日常", example: "The light switch is next to the door.", exampleMeaning: "电灯开关就在门旁。", translations: [.japanese: "スイッチ", .korean: "스위치", .spanish: "Interruptor", .french: "Interrupteur"]),
        .init(key: "forest", english: "Forest", meaning: "森林", pronunciation: "/ˈfɔːrɪst/", category: "自然", example: "We went for a walk in the forest.", exampleMeaning: "我们去森林里散步了。", translations: [.japanese: "森", .korean: "숲", .spanish: "Bosque", .french: "Forêt"]),
        .init(key: "tea", english: "Iced tea", meaning: "冰茶", pronunciation: "/aɪst tiː/", category: "食物", example: "A glass of iced tea, please.", exampleMeaning: "请来一杯冰茶。", translations: [.japanese: "アイスティー", .korean: "아이스티", .spanish: "Té helado", .french: "Thé glacé"]),
        .init(key: "apple", english: "Apple", meaning: "苹果", pronunciation: "/ˈæpəl/", category: "食物", example: "I eat an apple every day.", exampleMeaning: "我每天吃一个苹果。", translations: [.japanese: "りんご", .korean: "사과", .spanish: "Manzana", .french: "Pomme"]),
        .init(key: "banana", english: "Banana", meaning: "香蕉", pronunciation: "/bəˈnænə/", category: "食物", example: "This banana is ripe.", exampleMeaning: "这根香蕉熟了。", translations: [.japanese: "バナナ", .korean: "바나나", .spanish: "Plátano", .french: "Banane"]),
        .init(key: "bottle", english: "Bottle", meaning: "瓶子", pronunciation: "/ˈbɑːtəl/", category: "日常", example: "Bring a bottle of water.", exampleMeaning: "带一瓶水。", translations: [.japanese: "ボトル", .korean: "병", .spanish: "Botella", .french: "Bouteille"]),
        .init(key: "flower", english: "Flower", meaning: "花", pronunciation: "/ˈflaʊər/", category: "自然", example: "This flower smells lovely.", exampleMeaning: "这朵花闻起来很香。", translations: [.japanese: "花", .korean: "꽃", .spanish: "Flor", .french: "Fleur"]),
        .init(key: "cat", english: "Cat", meaning: "猫", pronunciation: "/kæt/", category: "动物", example: "The cat is sleeping in the sun.", exampleMeaning: "猫正在阳光下睡觉。", translations: [.japanese: "猫", .korean: "고양이", .spanish: "Gato", .french: "Chat"]),
        .init(key: "dog", english: "Dog", meaning: "狗", pronunciation: "/dɔːɡ/", category: "动物", example: "My dog loves long walks.", exampleMeaning: "我的狗喜欢长时间散步。", translations: [.japanese: "犬", .korean: "개", .spanish: "Perro", .french: "Chien"]),
        .init(key: "chair", english: "Chair", meaning: "椅子", pronunciation: "/tʃer/", category: "日常", example: "Please take a chair.", exampleMeaning: "请坐。", translations: [.japanese: "椅子", .korean: "의자", .spanish: "Silla", .french: "Chaise"]),
        .init(key: "shoe", english: "Shoe", meaning: "鞋子", pronunciation: "/ʃuː/", category: "日常", example: "I found my other shoe.", exampleMeaning: "我找到了另一只鞋。", translations: [.japanese: "靴", .korean: "신발", .spanish: "Zapato", .french: "Chaussure"])
    ]

    static func match(_ identifier: String) -> VocabularyEntry? {
        let aliases = ["doughnut": "donut", "mug": "cup", "coffee": "cup", "plant": "monstera",
                       "houseplant": "monstera", "adhesive_tape": "tape", "paper_clip": "clip",
                       "footwear": "shoe", "sandwich": "toast", "bagel": "bread", "woodland": "forest"]
        let keys = identifier.lowercased().split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        }
        for key in keys {
            if let entry = entries.first(where: { $0.key == (aliases[key] ?? key) }) { return entry }
        }
        return nil
    }
}
