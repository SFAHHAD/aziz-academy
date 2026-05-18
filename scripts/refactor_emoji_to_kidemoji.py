"""
Refactor bare-emoji Text() calls to KidEmoji.named(...) so AI-generated
asset PNGs can drop in without further code changes.

Pattern matched (with const variant):
  Text('🪙', style: TextStyle(fontSize: 14))    →   KidEmoji.named('coin', size: 14)
  const Text('🪙', style: TextStyle(fontSize: 14))   →   KidEmoji.named('coin', size: 14)
  const Text('🪙')                              →   KidEmoji.named('coin')
  Text('🪙')                                    →   KidEmoji.named('coin')

Files touched: explicit allowlist (priority UI surfaces only). JSON-content
emojis are NOT touched — those would require a different approach (parsing
strings and substituting Image widgets inline).

Idempotent: re-running won't double-refactor (already-converted call sites
are KidEmoji.named which doesn't match the Text() pattern).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
IMPORT_LINE = "import 'package:aziz_academy/core/widgets/kid_emoji.dart';"

# Emoji -> alias. Must be in sync with KidEmoji._aliases.
EMOJI_ALIASES = {
    '🪙': 'coin', '🏆': 'trophy', '✅': 'check', '❌': 'cross',
    '🎉': 'party', '🔥': 'fire', '💡': 'lightbulb', '🧠': 'brain',
    '🌍': 'earth', '📖': 'book', '📚': 'books', '🎯': 'target',
    '🚀': 'rocket', '⭐': 'star', '✨': 'sparkles', '❤': 'heart',
    '❤️': 'heart', '🕌': 'mosque', '⚡': 'lightning', '🔢': 'numbers',
    '😢': 'crying', '🔬': 'microscope', '🌟': 'glowing_star', '🦉': 'owl',
    '💥': 'collision', '🦊': 'fox', '🤝': 'handshake', '🎓': 'graduation',
    '🔒': 'lock', '🚩': 'flag', '📏': 'ruler', '✏️': 'pencil', '✏': 'pencil',
    '🌎': 'globe_americas', '🌏': 'globe_asia', '🛡': 'shield', '🛡️': 'shield',
    '🔍': 'magnifier', '🎨': 'art_palette', '🔮': 'crystal_ball', '🏅': 'medal',
    '💪': 'flexed_biceps', '🤔': 'thinking_face', '👍': 'thumbs_up',
    '🎲': 'game_die', '🕘': 'clock', '🏫': 'school', '📜': 'scroll',
    '🎊': 'confetti_ball', '📅': 'calendar', '🖨': 'printer', '🖨️': 'printer',
    '📊': 'chart', '📝': 'memo', '📱': 'phone',
}

PRIORITY_FILES = [
    'lib/features/home/home_screen.dart',
    'lib/features/home/splash_screen.dart',
    'lib/features/achievements/presentation/screens/trophy_room_screen.dart',
    'lib/core/widgets/celebration_overlay.dart',
    'lib/features/parent/presentation/parent_screen.dart',
]

# Build a regex that matches each emoji + its variation selector if present.
EMOJI_GROUP = '|'.join(re.escape(e) for e in sorted(EMOJI_ALIASES.keys(), key=len, reverse=True))

# Match: (const )?Text\(\s*'<EMOJI>'\s*(,\s*style:\s*TextStyle\(fontSize:\s*<N>\s*\))?\s*\)
PATTERN_FULL = re.compile(
    r"(const\s+)?Text\s*\(\s*'(" + EMOJI_GROUP + r")'\s*,\s*style:\s*TextStyle\s*\(\s*fontSize:\s*([\d.]+)\s*\)\s*\)"
)
PATTERN_BARE = re.compile(
    r"(const\s+)?Text\s*\(\s*'(" + EMOJI_GROUP + r")'\s*\)"
)


def refactor(text: str) -> tuple[str, int]:
    n = 0
    def repl_full(m: re.Match) -> str:
        nonlocal n
        emoji = m.group(2)
        size = m.group(3)
        alias = EMOJI_ALIASES.get(emoji)
        if not alias:
            return m.group(0)
        n += 1
        return f"KidEmoji.named('{alias}', size: {size})"

    def repl_bare(m: re.Match) -> str:
        nonlocal n
        emoji = m.group(2)
        alias = EMOJI_ALIASES.get(emoji)
        if not alias:
            return m.group(0)
        n += 1
        return f"KidEmoji.named('{alias}')"

    text = PATTERN_FULL.sub(repl_full, text)
    text = PATTERN_BARE.sub(repl_bare, text)
    return text, n


def ensure_import(text: str) -> str:
    if IMPORT_LINE in text:
        return text
    lines = text.split('\n')
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import = i
    if last_import == -1:
        return text  # no imports? skip
    lines.insert(last_import + 1, IMPORT_LINE)
    return '\n'.join(lines)


def main() -> int:
    total = 0
    for rel in PRIORITY_FILES:
        p = ROOT / rel
        if not p.exists():
            print(f"  skip   missing  {rel}")
            continue
        text = p.read_text(encoding='utf-8')
        new, n = refactor(text)
        if n > 0:
            new = ensure_import(new)
            p.write_text(new, encoding='utf-8')
            total += n
            print(f"  fixed  {n:3} call(s)  {rel}")
        else:
            print(f"  skip   no match  {rel}")
    print(f"\nRefactored {total} bare-emoji Text() calls to KidEmoji.named().")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
