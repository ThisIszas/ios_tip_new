import Foundation

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        return unicodeScalars.count == 1 && unicodeScalars.first?.properties.isEmojiPresentation ?? false
    }

    /// Checks if the scalars will be merged into and emoji
    var isCombinedIntoEmoji: Bool {
        return unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }

    var isEmoji: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

extension String {
    var isSingleEmoji: Bool {
        return count == 1 && containsEmoji
    }

    var containsEmoji: Bool {
        return contains { $0.isEmoji }
    }

    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains { !$0.isEmoji }
    }

    var emojiString: String {
        return emojis.map { String($0) }.reduce("", +)
    }

    var emojis: [Character] {
        filter { $0.isEmoji }
    }

    var emojiScalars: [UnicodeScalar] {
        return filter{ $0.isEmoji }.flatMap { $0.unicodeScalars }
    }
}

"A̛͚̖".containsEmoji // false
"3".containsEmoji // false
"3️⃣".isSingleEmoji // true
"👌🏿".isSingleEmoji // true
"🙎🏼‍♂️".isSingleEmoji // true
"👨‍👩‍👧‍👧".isSingleEmoji // true
"👨‍👩‍👧‍👧".containsOnlyEmoji // true
"Hello 👨‍👩‍👧‍👧".containsOnlyEmoji // false
"Hello 👨‍👩‍👧‍👧".containsEmoji // true
"👫 Héllo 👨‍👩‍👧‍👧".emojiString // "👫👨‍👩‍👧‍👧"
"👨‍👩‍👧‍👧".count // 1
"👫 Héllœ 👨‍👩‍👧‍👧".emojiScalars // [128107, 128104, 8205, 128105, 8205, 128103, 8205, 128103]
"👫 Héllœ 👨‍👩‍👧‍👧".emojis // ["👫", "👨‍👩‍👧‍👧"]
"👫 Héllœ 👨‍👩‍👧‍👧".emojis.count // 2
"👫👨‍👩‍👧‍👧👨‍👨‍👦".isSingleEmoji // false
"👫👨‍👩‍👧‍👧👨‍👨‍👦".containsOnlyEmoji // true
