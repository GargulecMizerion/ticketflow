# ADR-0004: VPS z docker-compose zamiast darmowych tierów i PaaS

**Status:** zaakceptowany · 2026-08-31

## Kontekst
Projekt ma mieć publiczne demo pod własnym adresem, z HTTPS, wdrażane automatycznie.
Docelowo to ~9 kontenerów: 6 serwisów JVM, Postgres, Redis, RabbitMQ, Keycloak,
plus stack obserwowalności. Realne zapotrzebowanie: **4-6 GB RAM**.

## Rozważane opcje

**Darmowe PaaS-y (Render, Railway, Fly.io)** — darmowe plany są liczone per usługa
i mają limity rzędu 512 MB. Przy 6 serwisach albo nie wejdziemy w limit, albo
spędzimy więcej czasu na obchodzeniu ograniczeń niż na nauce. Render usypia
darmowe instancje, co dla demo pod linkiem w CV jest dyskwalifikujące.

**Oracle Cloud Always Free** — kuszące, bo darmowe na zawsze. Ale: 15 czerwca 2026
Oracle **po cichu obciął** tier z 4 OCPU/24 GB do 2 OCPU/12 GB, bez ogłoszenia.
Do tego notoryczne „out of capacity" przy tworzeniu instancji ARM i ograniczenie
do jednego regionu wybranego przy zakładaniu konta. 12 GB nadal by wystarczyło,
ale to fundament, który może się ruszyć w trakcie projektu.

**VPS (Hetzner, Contabo, Mikr.us)** — płatne, ale przewidywalne. Hetzner podniósł
ceny w czerwcu 2026, mimo to CX32 (4 vCPU / 8 GB / 80 GB) to ok. 6,80 €/mies.
Przy 6 miesiącach projektu daje to ~40 € całości.

## Decyzja
VPS klasy 8 GB RAM, docker-compose, Caddy jako reverse proxy, deploy przez
GitHub Actions po SSH. Wdrożenie zaczyna się w **Sprincie 2**, nie na końcu.

## Uzasadnienie
- Przewidywalność jest ważniejsza niż darmowość, gdy projekt trwa pół roku.
  Cichy cut Oracle'a jest tego dobrą ilustracją.
- VPS uczy rzeczy, których PaaS **celowo przed tobą ukrywa**: SSH, firewall,
  reverse proxy, certyfikaty, limity pamięci JVM w kontenerze, backupy.
  Na rozmowie o pracę to jest różnica między „wdrażałem" a „klikałem deploy".
- Ten sam `docker-compose`, którego używasz lokalnie, działa na serwerze.
  Jedno narzędzie mniej do nauki na tym etapie.

## Konsekwencje
- (−) Koszt ~7 €/mies. i odpowiedzialność za aktualizacje bezpieczeństwa serwera.
- (−) Jeden serwer = jeden punkt awarii. Świadomie akceptowane: to demo, nie SLA.
- (+) Pełna kontrola i realne doświadczenie operacyjne.
- Jeśli budżet jest problemem: Mikr.us lub Oracle są akceptowalnym zamiennikiem.
  Przy Oracle pamiętaj, że to **ARM** — obrazy trzeba budować pod `linux/arm64`.
- Kubernetes świadomie odłożony. Naturalny następny krok po TF-58, jako osobny
  projekt: migracja tego samego stacku na k3s.
