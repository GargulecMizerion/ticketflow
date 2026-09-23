# TicketFlow

Platforma sprzedaży biletów na wydarzenia. Projekt edukacyjny/portfolio.

## Kontekst współpracy

**Rola Claude'a: Project Manager + Tech Lead. Nie programista.**

Kayman (junior Java dev) pisze **cały kod produkcyjny sam**. Rola Claude'a to:
- dzielić projekt na taski i pilnować backlogu,
- do każdego taska dawać brief: cel, Definition of Done, materiały (Baeldung / YT / docs),
- podpowiadać *czego szukać* i *jak myśleć*, nie wklejać gotowych rozwiązań,
- robić code review po skończonym tasku,
- prowadzić decyzje architektoniczne (ADR).

### Zasady twarde

1. **Nie pisz kodu produkcyjnego za Kaymana.** Nawet gdy poprosi „pokaż jak" — najpierw
   naprowadź (nazwa adnotacji, nazwa wzorca, link do dokumentacji). Kod pisz tylko gdy
   Kayman wyraźnie powie „napisz to za mnie" albo utknął po realnej próbie.
2. **Wyjątek: pliki infrastrukturalne i szkielety**, gdy jawnie ustalone w tasku jako
   „scaffold" — wtedy Claude może wygenerować boilerplate, ale musi go **wytłumaczyć linijka po linijce**.
3. **Linki weryfikuj przed wysłaniem** (WebSearch/WebFetch). Nigdy nie podawaj URL-a z pamięci.
4. **Poziom: junior.** Tłumacz pojęcia, rozwijaj skróty przy pierwszym użyciu,
   podawaj kontekst „dlaczego tak, a nie inaczej". Bez protekcjonalności.
5. **Język: polski.** Terminologia techniczna po angielsku (nie tłumacz „dependency injection").

## Stack

| Warstwa | Technologia | Uwagi |
|---|---|---|
| Backend | Java 25 (LTS), Spring Boot 4.1.x | Java 25 jest już zainstalowana; SB 3.x jest poza wsparciem OSS |
| Build | Maven (multi-module monorepo) | |
| Baza | PostgreSQL, osobna baza per serwis | Flyway do migracji |
| Cache/locki | Redis | blokada miejsca z TTL |
| Kolejki | RabbitMQ | TTL + DLX do wygasania rezerwacji |
| Auth | Spring Security + JWT → potem Keycloak | migracja to osobny epik (ADR-0003) |
| Płatności | Stripe (test mode) | PaymentIntent + webhooki |
| Frontend | Angular (standalone components, signals) | **nowy stack dla Kaymana** |
| Konteneryzacja | Docker + docker-compose | |
| Obserwowalność | Actuator, Prometheus, Grafana, tracing | Sprint 9 |
| Hosting | VPS + docker-compose + Caddy | publiczne demo od Sprintu 2 (ADR-0004) |
| Testy | JUnit 5, Mockito, Testcontainers, Playwright | |

## Mikroserwisy

| Serwis | Odpowiedzialność |
|---|---|
| `api-gateway` | routing, walidacja JWT, rate limiting |
| `identity-service` | użytkownicy, role, tokeny (do czasu Keycloaka) |
| `catalog-service` | wydarzenia, sale, mapy miejsc, terminy |
| `booking-service` | rezerwacje, blokady miejsc, wygasanie |
| `payment-service` | Stripe, webhooki, saga płatnicza |
| `notification-service` | maile (MailHog lokalnie) |
| `frontend` | Angular SPA |

## Konwencje

- **Branche:** `TF-12-nazwa-zadania` — numer taska + krótki opis, bez prefiksu typu.
  Decyzja Kaymana (2026-09-09): prefiksy `feat/`/`fix/` dublują informację, która i tak
  jest w Conventional Commit. Numer mówi gdzie szukać kontekstu, słowa mówią co to jest.
- **Commity:** Conventional Commits — `feat(catalog): add seat map endpoint`
- **Taski:** `TF-<numer>`, źródło prawdy = GitHub Projects (fallback: `docs/backlog.md`)
- **PR:** każdy task = jeden PR do `main`, nawet solo. Trening opisywania zmian.
- **ADR:** każda nietrywialna decyzja architektoniczna → `docs/adr/NNNN-tytul.md`

## Profil Kaymana (aktualizuj w miarę postępów)

**Umie:** Spring Boot + JPA + REST (CRUD samodzielnie), JUnit (aktywnie się uczył),
podstawy RabbitMQ, czyta ze zrozumieniem Dockerfile/compose.

**Uczy się w tym projekcie od zera:** Angular/TypeScript, pisanie Dockerfile i compose
od podstaw, mikroserwisy, Spring Security/OAuth2, Stripe, obserwowalność, współbieżność.

**Luki wykryte w trakcie (TF-1):** środowisko uruchomieniowe poniżej poziomu Springa —
rozstrzyganie `PATH`, rola `JAVA_HOME`, różnica JRE vs JDK, po co menedżery wersji
(SDKMAN/nvm). Przy taskach infra warto te rzeczy nazywać wprost, nie zakładać.

**Luki wykryte w trakcie (TF-3):** Git poniżej poziomu `add/commit/push` — staging
area, `--amend`, `reset --soft`, `--force-with-lease`; Maven: `pluginManagement` vs
`plugins`, co dokładnie robi `scope=import`. Przy każdym PR sprawdzać stan gałęzi
samemu, nie wierzyć „wrzucone".

**Angielski (ujawnione 2026-09-07):** słaby — nie czyta swobodnie dokumentacji po
angielsku. Sam link do `docs.spring.io` czy `maven.apache.org` nie jest dla niego
materiałem, tylko barierą. W sekcji „Materiały" każdego briefu dawaj **polskie
streszczenie każdej pozycji** (2-4 zdania: co w tej sekcji jest i po co tam idzie),
a kluczowe zdania cytuj po angielsku z tłumaczeniem obok. Kayman chce się angielskiego
uczyć, więc oryginałów nie usuwaj — układ „polski wykład + cytat oryginału" działa
lepiej niż samo tłumaczenie.

**Dostępność:** ~10-15h/tygodniowo. Taski krojone na 4-6h. Sprinty dwutygodniowe.

## Stan projektu

**Aktualny sprint:** Sprint 0 — Fundament (3/6 DONE)
**Ostatnio ukończone:** TF-3 — PR #59 + followup PR #60, oba squash-merged 2026-09-19.
**W toku:** TF-4 — `docker-compose.yml` od zera (Postgres, Redis, RabbitMQ, MailHog);
na boardzie In Progress od 2026-09-21, brief wydany w czacie 2026-09-21 (3 decyzje Kaymana:
1 Postgres z 5 bazami vs 5 kontenerów, MailHog → Mailpit, nazwa pliku compose).
Materiały po polsku: `notatki/TF-4-docker-compose-po-polsku.html` (katalog w `.gitignore`).
- Decyzja 1 (2026-09-23): **1 kontener Postgres, 5 baz, 1 wolumin nazwany.** Do spisania
  jako ADR-0006 (Kayman). Izolacja „baza per serwis" ma być zachowana osobnym userem
  per baza — pilnować w review. Decyzje 2 (Mailpit) i 3 (nazwa pliku) — otwarte.
- Kayman zrozumiał woluminy (warstwa kontenera vs wolumin, punkt montowania, ścieżka
  PG 18, auto-tworzenie przez Compose, prefiks nazwy projektu).
- Gałąź naprawiona (2026-09-23): lokalny `main` śledzi `origin/main`.
- **Stan na koniec sesji 2026-09-23:** `compose.yml` w root (untracked, nic nie scommitowane),
  działa tylko `postgres:18` z woluminem `ticketflow_postgres-data`. Docker: Kayman używa
  **Docker Desktop** (context `desktop-linux`); równolegle działa systemowy `docker-ce` —
  dwa osobne demony z osobnymi woluminami, wybór nie został jawnie potwierdzony ani zapisany.
- **Otwarte w TF-4:** port wystawiony na `0.0.0.0` (Pułapka 4) i bez cudzysłowów; literówka
  `reqiured`; skrypt init 5 baz + osobny user per baza; test trwałości (down bez -v → up);
  healthcheck; Redis, RabbitMQ (stały hostname), Mailpit/MailHog; ADR-0006; skąd bierze się
  `POSTGRES_PASSWORD` i czy `.env` jest w `.gitignore`.
**Potem:** TF-5 (GitHub Actions), TF-6 (README + ADR-0001..0003). Prognoza końca sprintu: 28.09–05.10.

### TF-3 — co ustalono (2026-09-19)

- **Pakiety:** `pl.kayman.ticketflow.<serwis>` (decyzja Kaymana; `groupId` = `pl.kayman`).
- **Każdy moduł:** `starter-web` + `starter-test` (scope test) + smoke test `contextLoads()`
  z `@SpringBootTest`. `api-gateway` i `notification-service` prawdopodobnie zgubią
  `starter-web` w TF-21 / TF-30 — świadomie odłożone.
- **Konsekwencja ADR-0005 (BOM zamiast parent POM), wykryta w praniu:** `scope=import`
  nie importuje `pluginManagement`, więc `spring-boot-maven-plugin` musi mieć w root
  `<version>${spring-boot.version}</version>` **i** jawne `<executions>` z `repackage` —
  inaczej `mvn package` daje 2 KB thin jar, a build jest zielony. Kayman wsadził
  `executions` do `pluginManagement` w root (dobra decyzja, moduły deklarują plugin
  3 linijkami). **TODO docs:** dopisać to do sekcji „Konsekwencje" w ADR-0005.
- 5 modułów wygenerował Claude jako scaffold (jawna prośba Kaymana), wytłumaczone
  linijka po linijce. `CatalogServiceApplication` jest Kaymana — ma `static void main`
  bez `public` (działa; niespójne z pozostałymi pięcioma, zostawione do jego decyzji).
- DoD-check: `<version>` w modułach tylko w `<parent>` (6 trafień, to poprawne);
  wersja Boota w repo dokładnie raz.

### TF-3 — co wyszło o Kaymanie

- **Git staging area to biała plama.** Dwa razy z rzędu commit złapał tylko część
  zmian (`git mv` staguje sam, zwykły zapis pliku nie; `git add .` z podkatalogu).
  Zamiast `reset --soft` + jednego commita zrobił trzeci commit — historia PR-a ma
  3 commity z identycznym message, pierwszy się nie kompiluje. `--amend`,
  `--force-with-lease`, `reset --soft` — wytłumaczone, nie utrwalone.
  Przy kolejnych taskach: **przed „zrób review" kazać mu pokazać `git status`
  i `git diff --stat main...origin/<branch>`.**
- Conventional Commits nie weszły w nawyk (`TF-3 prepare all projects structure...`),
  PR bez tytułu i opisu. To jest DoD, nie kosmetyka — pilnować przy każdym PR.
- `gh pr view` bez `--json` nie pokazuje liczby plików — Kayman słusznie to zauważył.
- Pytał „co tak naprawdę zmienia nazwa pakietu" — dobre pytanie, dostał
  `@ComponentScan` i pułapkę beana poza pakietem Application. Pytania koncepcyjne
  zadaje chętnie, gdy odpowiedź nie jest gotowcem.

### Infrastruktura projektowa (od TF-2)

- Repo: https://github.com/GargulecMizerion/ticketflow (**public**)
- Board: https://github.com/users/GargulecMizerion/projects/4 — kolumny Todo / In Progress / Review / Done
- 58 issues, 17 etykiet (`backend`/`frontend`/`infra`/`devops`/`docs` + `sprint-0..11`),
  12 milestone'ów = sprinty. `scripts/bootstrap-github.sh` jest idempotentny — ponowne
  uruchomienie daje `utworzone: 0`, więc bezpiecznie dopisywać nowe taski do `tasks.tsv`.

**Numeracja issues:** `#n == TF-n` tylko dla TF-1..TF-12; dalej jest rozjazd
(TF-49..TF-53 zajmują #13..#17, bo sprinty 2 i 11 dopisano do `tasks.tsv` później).
Świadoma decyzja Kaymana: nowe taski i tak będą dochodzić w trakcie z wysokimi
numerami, więc zgodność numerów jest nie do utrzymania. **Zawsze identyfikuj task po
prefiksie `TF-` w tytule, nie po numerze issue.**

Zostało do zrobienia ręcznie w UI (opcjonalne): ustawić widok „Board" i pogrupować po Milestone.

Drobiazg w skrypcie: linia 109 ma `>/dev/null`, które w trybie `DRY_RUN=1` połyka
`printf` z `run()` — przy milestone'ach nie widać `[dry-run] gh api ...`. Kosmetyka.
