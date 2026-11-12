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
# The schema checks shape only, but what it can say it must: these invalid
# cases break a rule of shape, so the schema has to refuse them too.
for name in ["bad-dice", "dice-too-many", "integer-too-big", "media-path-outside-folder",
             "unknown-key", "two-exits", "no-way-out", "enemy-health-at-least-1"]:
    story = json.load(open(f"conformance/cases/invalid/{name}.json"))["story"]
    if validator.is_valid(story):
        print(f"conformance/cases/invalid/{name}.json: the schema accepts it")
        failed += 1
print(f"{len(paths)} stories, {failed} not matching the schema")
sys.exit(1 if failed else 0)
