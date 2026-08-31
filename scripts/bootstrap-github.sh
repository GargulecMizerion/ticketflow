#!/usr/bin/env bash
#
# Wrzuca backlog z tasks.tsv na GitHuba: repo -> etykiety -> milestone'y -> issues -> board.
#
# Uzycie:
#   DRY_RUN=1 ./scripts/bootstrap-github.sh    # pokaz co zrobi, nic nie tworz
#   ./scripts/bootstrap-github.sh              # wykonaj
#
# Skrypt jest idempotentny: mozna go puscic ponownie, pominie to co juz istnieje.

set -euo pipefail

REPO_NAME="ticketflow"
PROJECT_TITLE="TicketFlow"
VISIBILITY="public"          # zmien na "private" jesli nie chcesz publicznego repo
DRY_RUN="${DRY_RUN:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKS_FILE="$SCRIPT_DIR/tasks.tsv"

# Nazwy sprintow -> tytuly milestone'ow. Uzywane tez przy etykietach,
# wiec musi byc zadeklarowane przed pierwszym uzyciem.
declare -A SPRINT_NAME=(
  [0]="Fundament"          [1]="catalog-service"     [2]="Pierwszy deploy"
  [3]="Angular od zera"    [4]="Auth + gateway"      [5]="Booking + wspolbieznosc"
  [6]="RabbitMQ"           [7]="Platnosci"           [8]="Keycloak"
  [9]="Obserwowalnosc"    [10]="Realtime + finisz"  [11]="Hardening produkcyjny"
)

# run() wykonuje polecenie albo tylko je wypisuje, zaleznie od DRY_RUN.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# --- 1. Preflight -----------------------------------------------------------
say "Sprawdzam wymagania"

command -v gh >/dev/null || { echo "BLAD: brak 'gh'. Zainstaluj GitHub CLI (task TF-1)."; exit 1; }
command -v jq >/dev/null || { echo "BLAD: brak 'jq'."; exit 1; }
[[ -f "$TASKS_FILE" ]]    || { echo "BLAD: nie znaleziono $TASKS_FILE"; exit 1; }

gh auth status >/dev/null 2>&1 || { echo "BLAD: nie jestes zalogowany. Uruchom: gh auth login"; exit 1; }

# GitHub Projects (v2) to osobne API i wymaga dodatkowego uprawnienia 'project'.
# Domyslny 'gh auth login' go NIE nadaje.
if ! gh auth status 2>&1 | grep -q 'project'; then
  echo "BLAD: token nie ma uprawnienia 'project'."
  echo "      Uruchom: gh auth refresh -s project,read:project"
  exit 1
fi

OWNER="$(gh api user --jq .login)"
echo "  konto GitHub: $OWNER"
echo "  tryb: $([[ "$DRY_RUN" == "1" ]] && echo 'DRY RUN (nic nie zostanie utworzone)' || echo 'WYKONANIE')"

# --- 2. Repozytorium --------------------------------------------------------
say "Repozytorium"

if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
  echo "  '$OWNER/$REPO_NAME' juz istnieje - pomijam"
else
  echo "  tworze '$OWNER/$REPO_NAME' ($VISIBILITY)"
  run gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
fi

# --- 3. Etykiety ------------------------------------------------------------
# Kolor per obszar - zeby board dalo sie czytac jednym rzutem oka.
say "Etykiety"

create_label() {
  local name="$1" color="$2" desc="$3"
  if gh label list --repo "$OWNER/$REPO_NAME" --json name --jq '.[].name' 2>/dev/null | grep -qx "$name"; then
    echo "  '$name' juz istnieje"
  else
    echo "  + $name"
    run gh label create "$name" --repo "$OWNER/$REPO_NAME" --color "$color" --description "$desc"
  fi
}

create_label "backend"  "1f6feb" "Java / Spring"
create_label "frontend" "d29922" "Angular / TypeScript"
create_label "infra"    "8250df" "Docker, bazy, brokery"
create_label "devops"   "2da44e" "CI, obserwowalnosc, deploy"
create_label "docs"     "6e7781" "Dokumentacja i ADR"

for s in $(seq 0 $((${#SPRINT_NAME[@]} - 1))); do
  create_label "sprint-$s" "ededed" "Sprint $s"
done

# --- 4. Milestone'y = sprinty ----------------------------------------------
# Sprint mapujemy na milestone, bo GitHub pokazuje przy nim pasek postepu.
say "Milestone'y (sprinty)"


EXISTING_MS="$(gh api "repos/$OWNER/$REPO_NAME/milestones?state=all&per_page=100" --jq '.[].title' 2>/dev/null || true)"

for s in $(seq 0 $((${#SPRINT_NAME[@]} - 1))); do
  title="Sprint $s - ${SPRINT_NAME[$s]}"
  if grep -qxF "$title" <<<"$EXISTING_MS"; then
    echo "  '$title' juz istnieje"
  else
    echo "  + $title"
    run gh api "repos/$OWNER/$REPO_NAME/milestones" -f title="$title" >/dev/null
  fi
done

# --- 5. Board (GitHub Projects v2) -----------------------------------------
say "Board"

PROJECT_NUMBER="$(gh project list --owner "$OWNER" --format json \
  | jq -r --arg t "$PROJECT_TITLE" '.projects[] | select(.title==$t) | .number' | head -1)"

if [[ -n "$PROJECT_NUMBER" ]]; then
  echo "  board '$PROJECT_TITLE' juz istnieje (nr $PROJECT_NUMBER)"
elif [[ "$DRY_RUN" == "1" ]]; then
  echo "  [dry-run] gh project create --owner $OWNER --title $PROJECT_TITLE"
  PROJECT_NUMBER="???"
else
  PROJECT_NUMBER="$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" \
    --format json | jq -r '.number')"
  echo "  utworzony board nr $PROJECT_NUMBER"
fi

# --- 6. Issues --------------------------------------------------------------
say "Taski"

EXISTING_ISSUES="$(gh issue list --repo "$OWNER/$REPO_NAME" --state all --limit 500 \
  --json title --jq '.[].title' 2>/dev/null || true)"

created=0; skipped=0

# IFS=$'\t' rozbija linie po tabulatorach. Ostatnie pole (title) moze zawierac spacje.
while IFS=$'\t' read -r id sprint area est title; do
  [[ -z "${id:-}" || "$id" == \#* ]] && continue

  full_title="$id: $title"

  if grep -qxF "$full_title" <<<"$EXISTING_ISSUES"; then
    echo "  = $full_title (juz istnieje)"
    skipped=$((skipped+1)); continue
  fi

  body="$(cat <<BODY
**Sprint:** $sprint · **Obszar:** $area · **Estymata:** ${est}h

### Definition of Done
_Uzupelnij przez \`/pm brief $id\` przed rozpoczeciem._

- [ ] Kod dziala lokalnie (\`docker compose up\`)
- [ ] Testy napisane i przechodza
- [ ] PR do \`main\` z opisem zmian

### Materialy
_Dostarcza \`/pm brief $id\`._

---
Pelny kontekst: [\`docs/backlog.md\`](../blob/main/docs/backlog.md)
BODY
)"

  echo "  + $full_title"
  if [[ "$DRY_RUN" != "1" ]]; then
    url="$(gh issue create --repo "$OWNER/$REPO_NAME" \
      --title "$full_title" --body "$body" \
      --label "$area" --label "sprint-$sprint" \
      --milestone "Sprint $sprint - ${SPRINT_NAME[$sprint]}")"
    gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" >/dev/null
    sleep 1   # GitHub ma limit na masowe tworzenie tresci - nie spieszmy sie
  fi
  created=$((created+1))
done < "$TASKS_FILE"

say "Gotowe"
echo "  utworzone: $created   pominiete: $skipped"
echo "  board:  https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo "  issues: https://github.com/$OWNER/$REPO_NAME/issues"
echo
echo "  Zostalo do zrobienia recznie w UI (30 sekund):"
echo "   - dodaj kolumny statusu: Todo / In Progress / Review / Done"
echo "   - ustaw widok 'Board' i pogrupuj po Milestone"
