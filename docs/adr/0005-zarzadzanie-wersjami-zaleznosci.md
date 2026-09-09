# ADR-0005: Import `spring-boot-dependencies` w parencie zamiast dziedziczenia po `spring-boot-starter-parent`

**Status:** zaakceptowany · 2026-09-09

## Kontekst

Monorepo ma docelowo 6 modułów Mavena (`api-gateway`, `identity-service`,
`catalog-service`, `booking-service`, `payment-service`, `notification-service`),
budowanych jednym reaktorem. Wszystkie muszą używać **tej samej** wersji Spring Boota
i tych samych wersji bibliotek pomocniczych (MapStruct, Testcontainers, stripe-java).
Rozjazd wersji między serwisami to klasa błędów, która ujawnia się dopiero w runtime
i jest kosztowna w diagnozie.

Pytanie do rozstrzygnięcia w TF-3: **skąd moduły biorą wersje zależności.**

Kluczowa właściwość Mavena, wokół której kręci się cała decyzja: `<parent>`
(dziedziczenie) przenosi w dół `dependencyManagement`, `properties`, `pluginManagement`
i całą sekcję `build`. Natomiast `<scope>import</scope>` (BOM) przenosi **wyłącznie**
`dependencyManagement` — nic poza tym.

## Rozważane opcje

**A. Korzeniowy POM dziedziczy po `spring-boot-starter-parent`, moduły po korzeniu.**
Najkrótsza droga i domyślny wybór w większości tutoriali. Dostajesz za darmo
konfigurację compilera, kodowanie UTF-8, filtrowanie zasobów, `spring-boot-maven-plugin`
skonfigurowany, ~150 linii sensownych ustawień build, których nie musisz pisać.
Wada: cały projekt — łącznie z modułami, które nigdy nie będą aplikacją Spring Boot
(przyszły `common-events` z DTO zdarzeń, ewentualny moduł BOM) — dziedziczy build
zaprojektowany pod aplikację Spring Boot. Jedyne miejsce na `<parent>` jest zajęte
przez Springa, więc własna konfiguracja projektowa musi się w tę hierarchię wcisnąć.

**B. Korzeniowy POM importuje `spring-boot-dependencies` jako BOM, moduły dziedziczą
po korzeniu.** Korzeń jest własnością projektu, nie Springa. Spring dostarcza wyłącznie
listę ~400 wersji; konfigurację build piszemy sami. Wada: to, co w opcji A jest za
darmo, tutaj jest do napisania ręcznie — `maven.compiler.release`, UTF-8,
`spring-boot-maven-plugin` w `pluginManagement`. Nadpisanie pojedynczej wersji
z BOM-u wymaga wpisu **powyżej** bloku importu, nie property (jak w opcji A).

**C. Osobny moduł `ticketflow-bom`, importowany przez każdy serwis.**
Wzorzec z dużych projektów — tak dystrybuowany jest np. Spring Cloud. Moduł zawiera
sam `dependencyManagement` i żadnego kodu. Wady przy tej skali: serwisy i tak
potrzebują `<parent>` wskazującego na korzeń (bo BOM nie przenosi `pluginManagement`),
więc powstają **dwa kanały zamiast jednego**, a blok importu trzeba powielić w sześciu
plikach. Do tego import-scope BOM-u z tego samego reaktora bywa zawodny przy budowie
pojedynczego modułu (`mvn -pl`) bez wcześniejszego `install` całości.

## Decyzja

**Opcja B.** Korzeniowy `pom.xml` z `<packaging>pom</packaging>` importuje
`spring-boot-dependencies` (`<type>pom</type>`, `<scope>import</scope>`) do własnej
sekcji `dependencyManagement` i dokłada tam wersje bibliotek spoza ekosystemu Spring
Boota. Moduły serwisów mają wyłącznie `<parent>` wskazujący na korzeń i deklarują
zależności **bez `<version>`**.

## Uzasadnienie

- **Jedno miejsce prawdy o wersjach jest własnością projektu, nie frameworka.**
  Za pół roku dojdzie Keycloak (TF-37) i Resilience4j (TF-44) — biblioteki, których
  Spring Boot BOM nie obejmuje. W opcji B leżą one dokładnie tam, gdzie wszystko inne.
- **Opcja C rozwiązuje problem, którego projekt nie ma.** BOM jako osobny artefakt
  istnieje dla konsumentów **spoza drzewa dziedziczenia**. Wszystkie moduły siedzą
  w jednym reaktorze i dziedziczą po korzeniu — dziedziczenie już przenosi
  `dependencyManagement` w dół. Osobny moduł byłby drugą drogą tam, gdzie jest już
  pierwsza.
- **Opcja C nie zastępuje B, tylko się do niej dokłada** — serwisy nadal potrzebują
  `<parent>` po konfigurację pluginów. Koszt: +1 moduł i 6 kopii bloku importu.
  Zysk: zdolność, z której dziś nikt nie korzysta.
- **Cel edukacyjny.** Opcja A ukrywa mechanizm — Kayman dostałby działający build,
  nie wiedząc, skąd biorą się wersje. Opcja B wymusza zrozumienie różnicy między
  `dependencies` a `dependencyManagement` oraz działania `scope=import`. To jest
  wiedza, której opcja A nie daje, a która wraca na rozmowach o pracę.

## Konsekwencje

- (−) **Plugin management nie przychodzi z BOM-u.** Trzeba samodzielnie skonfigurować
  `maven.compiler.release` dla Javy 25, kodowanie UTF-8 źródeł i zasobów oraz
  `spring-boot-maven-plugin` w `<pluginManagement>`. To jest jednorazowy koszt w TF-3.
- (−) Brak UTF-8 w konfiguracji objawi się dopiero przy polskich znakach w danych
  seed (TF-8) lub szablonach maili (TF-30), i będzie zależny od locale maszyny —
  czyli „u mnie działa" w najgorszej postaci. Ustawić od razu.
- (−) Nadpisanie pojedynczej wersji z BOM-u wymaga jawnego wpisu **przed** blokiem
  importu. Property w stylu `<spring.version>` nie zadziała, inaczej niż w opcji A.
- (+) Korzeniowy POM jest czytelny — widać w nim wyłącznie decyzje projektu.
- (+) Moduły niebędące aplikacjami Spring Boot wpinają się bez obchodzenia
  cudzej konfiguracji build.

## Kiedy tę decyzję zrewidować

Sygnałem do przejścia na opcję C jest **pierwszy konsument spoza reaktora**:
rozbicie monorepo na repozytoria per serwis albo wystawienie modułu współdzielonego
do zewnętrznego registry. Migracja jest mechaniczna — przeniesienie bloku
`dependencyManagement` do nowego modułu i dopisanie importu w serwisach, bez zmian
w kodzie Javy. Dopóki wszystko buduje się jednym reaktorem, opcja C to koszt bez zysku.
