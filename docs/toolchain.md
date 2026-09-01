# Toolchain

Wersje narzędzi, na których projekt jest rozwijany. Stan na **2026-09-01** (TF-1).

Jeśli coś przestanie się budować, zacznij od porównania swoich wersji z tą tabelą.

## Wersje

| Narzędzie | Wersja | Skąd | Dlaczego ta |
|---|---|---|---|
| JDK | Temurin 25.0.4 | SDKMAN (`25.0.4-tem`) | Java 25 to aktualne LTS. Temurin — neutralny build Eclipse Adoptium, ten sam, którego używają oficjalne obrazy Dockera, więc lokalnie i w kontenerze mamy tę samą JVM. |
| Maven | 3.9.16 | SDKMAN | Ostatnie stabilne. Maven 4.0.0 jest wciąż w RC (rc-6, lipiec 2026) i zmienia model POM-ów — nie chcemy tego debugować równolegle z nauką projektu. Spring Boot 4.1 wymaga min. 3.6.3. |
| Node.js | 24.20.0 (Krypton) | nvm | Active LTS. Node 26 jest nowszy, ale wchodzi w LTS dopiero w październiku 2026. |
| npm | 11.19.0 | razem z Node | — |
| Docker | 29.6.1 | dnf | Pakiet systemowy, wymaga demona — nie ma sensu wersjonować per-user. |
| Docker Compose | v5.1.3 | plugin Dockera | Wołany jako `docker compose` (podkomenda), nie `docker-compose` (osobny, wycofany skrypt). |
| gh CLI | 2.87.3 | dnf | — |
| SDKMAN | 5.23.0 | instalator ze sdkman.io | Zarządza JDK i Mavenem. |
| nvm | 0.40.7 | instalator z GitHuba | Zarządza Node'em. |

## Jak to jest poskładane

**JDK i Maven idą przez SDKMAN, Node przez nvm.** Oba narzędzia trzymają swoje wersje
w katalogu domowym (`~/.sdkman`, `~/.nvm`) i dopisują się na początek `PATH`. Dzięki temu:

- nie potrzeba `sudo` do zmiany wersji,
- nie ma konfliktu z pakietami systemowymi,
- przełączenie wersji Javy na potrzeby testu to jedno polecenie, nie reinstalacja systemu.

Wpięcie w shell siedzi na końcu `~/.bashrc` — SDKMAN **musi** być ostatni, inaczej jego
ustawienie `PATH` zostanie nadpisane przez późniejsze linie.

SDKMAN ustawia `JAVA_HOME` automatycznie (na `~/.sdkman/candidates/java/current`),
więc nie ma potrzeby ustawiać jej ręcznie.

## Weryfikacja

W **świeżo otwartym** terminalu:

```bash
java -version      # openjdk 25.0.4, Temurin
javac -version     # javac 25.0.4    <- to jest ten ważny
mvn -v             # 3.9.16, Java version: 25.0.4, vendor: Eclipse Adoptium
node -v            # v24.x
gh auth status     # Logged in to github.com
docker compose version
```

Jeśli działa dopiero po `source ~/.bashrc` — konfiguracja shella jest zepsuta i naprawa
tego jest tańsza teraz niż w środku sprintu.

## Pułapka: JRE to nie JDK

Na tej maszynie systemowa Java (`/usr/lib/jvm/java-25-openjdk`, pakiet
`java-25-openjdk-headless`) zawiera **wyłącznie** `java`, `keytool` i `rmiregistry`.
Nie ma `javac` — kompilatora. Uruchomi skompilowany program, ale nie skompiluje ani jednej klasy.

Do kompilowania potrzebny jest JDK (`java-25-openjdk-devel` z dnf albo — jak tutaj —
JDK z SDKMAN-a). **`mvn -v` tego nie wykryje**: pokazuje JVM, na której działa sam Maven,
a Maven do działania potrzebuje tylko JRE. Błąd wyjdzie dopiero przy `mvn compile`.

Sprawdzian jest jeden: `javac -version`.

## Zmiana wersji Javy

```bash
sdk list java                # co jest dostępne
sdk install java 21.0.12-tem # doinstaluj obok
sdk use java 21.0.12-tem     # tylko bieżący terminal
sdk default java 25.0.4-tem  # domyślna we wszystkich kolejnych
```

Przyda się, gdy trzeba sprawdzić, czy problem jest w kodzie, czy w wersji JVM.
