extends Node
## ContentLoader.gd
##
## Tiny shared helper (autoload) so every script reads its content the same
## way, instead of repeating file-reading code. Teachers editing
## content/*.json do not need to touch this file.

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("ContentLoader: missing content file %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("ContentLoader: %s did not contain a JSON object" % path)
		return {}
	return parsed

## Convenience: loads content/principles.json and returns it keyed by id,
## so mode scripts can look up a principle's name/definition/tip in one line.
func load_principles() -> Dictionary:
	var data := load_json("res://content/principles.json")
	var by_id: Dictionary = {}
	for p in data.get("principles", []):
		by_id[p["id"]] = p
	return by_id
