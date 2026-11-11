"""Checks spec/story.schema.json against the conformance stories.

Every play and lint case story must match the schema; so must any extra story
files given as arguments. Needs `pip install jsonschema`.
Run from the repository root: python3 tools/check_schema.py [story.json...]
"""
import glob
import json
import sys

from jsonschema import Draft202012Validator

schema = json.load(open("spec/story.schema.json"))
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)

failed = 0
paths = sorted(glob.glob("conformance/cases/play/*.json") + glob.glob("conformance/cases/lint/*.json")) + sys.argv[1:]
for path in paths:
    data = json.load(open(path))
    stories = list(data["stories"].values()) if "stories" in data else [data.get("story", data)]
    for story in stories:
        errors = sorted(validator.iter_errors(story), key=lambda e: list(e.path))
        for e in errors[:5]:
            print(f"{path}: {'/'.join(map(str, e.path)) or '(root)'}: {e.message}")
        failed += bool(errors)
print(f"{len(paths)} stories, {failed} not matching the schema")
sys.exit(1 if failed else 0)
