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

- **Branche:** `feat/TF-12-nazwa`, `fix/TF-33-nazwa`, `chore/...`
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

**Dostępność:** ~10-15h/tygodniowo. Taski krojone na 4-6h. Sprinty dwutygodniowe.

## Stan projektu

**Aktualny sprint:** Sprint 0 — Fundament (2/6 DONE)
**Ostatnio ukończone:** TF-2 — repo + board (2026-09-02).
**Następny task:** TF-3 — Maven multi-module: parent POM + puste moduły serwisów (3h).

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
