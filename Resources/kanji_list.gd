extends Resource
class_name KanjiList
## KanjiList
##
## Container resource that holds an array of KanjiEntry resources.
## Used by VocabDatabase to load kanji data from .tres files.

## The list of kanji entries in this collection.
@export var entries: Array[KanjiEntry] = []
