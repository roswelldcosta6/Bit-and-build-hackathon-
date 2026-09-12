import os, json, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))

# Point this at the extracted dataset. Override without editing code:
#   ISL_DATASET_DIR="/path/to/INDIAN SIGN LANGUAGE ANIMATED VIDEOS" python3 build_from_dataset.py
DATASET_DIR = "INDIAN SIGN LANGUAGE ANIMATED VIDEOS "
SRC = os.environ.get("ISL_DATASET_DIR") or os.path.join(HERE, DATASET_DIR)
ASSET_PREFIX = "assets/isl/"

# Where the copied clips live, relative to this file. The `video` field written
# into the manifests is relative to the Flutter project root.
ASSETS_DIR = os.path.join(HERE, "assets", "isl")

def gloss_from_filename(name):
    return name.upper().replace(" ", "_")

def probe_duration(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", path],
        capture_output=True, text=True
    ).stdout
    return round(float(json.loads(out)["format"]["duration"]), 2)

# Hindi labels come from hindi_lexicon.json — the single source of truth shared
# with text_to_isl.py — so the word map and the published labels can never
# drift apart. Words we are not confident translating are simply absent there
# (better to omit a label than guess one).
with open(os.path.join(HERE, "hindi_lexicon.json"), encoding="utf-8") as f:
    HINDI = json.load(f).get("labels", {})

if not os.path.isdir(SRC):
    raise SystemExit(
        f"Dataset folder not found: {SRC}\n"
        f"Extract the dataset and point at it explicitly with:\n"
        f'  ISL_DATASET_DIR="/path/to/{DATASET_DIR.strip()}" python3 build_from_dataset.py'
    )

entries = []
files = sorted(f for f in os.listdir(SRC) if f.lower().endswith(".mp4"))
for fname in files:
    stem = fname[:-4]
    gloss = gloss_from_filename(stem)
    dur = probe_duration(os.path.join(SRC, fname))
    entries.append({
        "gloss": gloss,
        "english": stem.lower(),
        "hindi": HINDI.get(gloss),
        "video_file": fname,
        "video": ASSET_PREFIX + fname,
        "duration": dur,
    })

# Non-fatal warnings: these do not stop the build, but they are the things that
# silently break demo coverage if nobody looks at them.
missing_assets = [e["video_file"] for e in entries
                  if not os.path.exists(os.path.join(ASSETS_DIR, e["video_file"]))]
if missing_assets:
    print(f"WARNING: {len(missing_assets)} clip(s) not found under {ASSETS_DIR}:")
    for f in missing_assets[:10]:
        print(f"  - {f}")

unlabelled = [e["gloss"] for e in entries if not e["hindi"]]
print(f"Hindi labels: {len(entries) - len(unlabelled)}/{len(entries)} signs "
      f"({len(unlabelled)} left untranslated on purpose)")

# Sanity: no duplicate glosses, every file accounted for
glosses = [e["gloss"] for e in entries]
assert len(glosses) == len(set(glosses)), "duplicate glosses found"
assert len(entries) == len(files)

# isl_dictionary.json
isl_dictionary = {}
for e in entries:
    d = {"english": e["english"], "video": e["video"]}
    if e["hindi"]:
        d["hindi"] = e["hindi"]
    isl_dictionary[e["gloss"]] = d

with open("isl_dictionary.json", "w", encoding="utf-8") as f:
    json.dump(isl_dictionary, f, ensure_ascii=False, indent=2, sort_keys=True)

# video_manifest.json (video-only manifest, per deliverables list)
video_manifest = {}
for e in entries:
    video_manifest[e["gloss"]] = {
        "video": e["video"],
        "duration": e["duration"],
        "english": e["english"],
        **({"hindi": e["hindi"]} if e["hindi"] else {}),
    }

with open("video_manifest.json", "w", encoding="utf-8") as f:
    json.dump(video_manifest, f, ensure_ascii=False, indent=2, sort_keys=True)

print(f"Built dictionary with {len(entries)} signs.")
print("Sample:", list(isl_dictionary.items())[:3])
