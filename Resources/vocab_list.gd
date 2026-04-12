extends Resource
class_name VocabList
## VocabList
##
## Container resource that holds an array of VocabWord resources.
## Used by VocabDatabase to load vocabulary from .tres files.

## The list of vocabulary words in this collection.
@export var words: Array[VocabWord] = []
