#!/data/data/com.termux/files/usr/bin/bash
export BASE="$HOME/kikeymods-repo"
P="$BASE/mods.json"
cd "$HOME" || exit 1

if [ ! -d "$BASE/.git" ]; then
  git clone https://github.com/galag1/kikeymods-catalog "$BASE" || exit 1
fi

sync() {
  git -C "$BASE" rebase --abort 2>/dev/null
  git -C "$BASE" pull --rebase --autostash origin main
}

cat > "$HOME/.kikeymods_edit.py" <<'PY'
import json, sys, os
from pathlib import Path
p = Path(os.environ["BASE"]) / "mods.json"
d = json.loads(p.read_text())
mods = d.setdefault("mods", [])
action = sys.argv[1]
if action == "list":
    if not mods:
        print("No mods found.")
    else:
        for i, m in enumerate(mods, 1):
            print(f'{i}. {m.get("name","Unnamed")} [{m.get("id","")}]')
    sys.exit(0)
if action == "add":
    old = {}
else:
    try:
        n = int(input("Enter mod number: "))
        if not 1 <= n <= len(mods):
            raise ValueError
    except ValueError:
        print("Invalid mod number.")
        sys.exit(1)
    old = mods[n-1]
    print("\nSelected:", old.get("name", "Unnamed"))
    if action == "delete":
        if input("Delete this mod? (y/N): ").strip().lower() != "y":
            print("Cancelled.")
            sys.exit(1)
        mods.pop(n-1)
        d["mods"] = mods
        p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        print("Deleted successfully.")
        sys.exit(0)
print("Press Enter to keep the current value.")
def ask(label, key):
    current = old.get(key, "")
    value = input(f"{label} [{current}]: ").strip()
    return value if value else current
id = ask("Mod ID", "id")
name = ask("Mod name", "name")
category = ask("Category", "category")
description = ask("Description", "description")
image = ask("Image URL", "image")
url = ask("ModsFire URL", "url")
if not id or not name or not url.startswith(("https://", "http://")):
    print("ERROR: ID, name, and valid URL are required.")
    sys.exit(1)
if any(m.get("id", "").lower() == id.lower() and m is not old for m in mods):
    print("ERROR: Another mod already uses that ID.")
    sys.exit(1)
mod = {"id": id, "name": name, "category": category,
       "description": description, "image": image, "url": url}
if action == "add":
    mods.append(mod)
else:
    mods[n-1] = mod
d["mods"] = mods
p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print("Saved:", name)
PY

echo "Kinukuha ang latest galing GitHub..."
sync || echo "Hindi naka-sync, check internet."

while true; do
  echo
  echo "===== KIKEY MODS MANAGER ====="
  echo "Folder: $BASE"
  echo "1. ADD MOD"
  echo "2. UPDATE MOD"
  echo "3. DELETE MOD"
  echo "4. EXIT"
  read -r -p "Choose [1-4]: " choice
  case "$choice" in
    1) sync; python3 "$HOME/.kikeymods_edit.py" add || continue ;;
    2) sync; python3 "$HOME/.kikeymods_edit.py" list; python3 "$HOME/.kikeymods_edit.py" update || continue ;;
    3) sync; python3 "$HOME/.kikeymods_edit.py" list; python3 "$HOME/.kikeymods_edit.py" delete || continue ;;
    4) exit 0 ;;
    *) echo "Invalid choice."; continue ;;
  esac

  if python3 -m json.tool "$P" >/dev/null \
     && git -C "$BASE" add mods.json \
     && { git -C "$BASE" commit -m "Manage mods catalog" || true; } \
     && git -C "$BASE" pull --rebase -X theirs origin main \
     && git -C "$BASE" push origin main; then
    echo "SUCCESS! Uploaded to GitHub."
  else
    git -C "$BASE" rebase --abort 2>/dev/null
    echo "Upload FAILED. Check the error above."
  fi
done
