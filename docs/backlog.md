# TicketFlow — backlog

Sprinty dwutygodniowe, ~10-15h/tydzień → ~20-30h na sprint.
Estymaty są dla **juniora uczącego się danej technologii**, nie dla seniora.
Szacowany czas całości: **~5 miesięcy**.

Legenda statusów: `TODO` · `IN PROGRESS` · `REVIEW` · `DONE`

---

## Sprint 0 — Fundament (~16h)

Cel: działające `docker compose up`, pusty ale kompilujący się monorepo, CI na zielono.

| ID | Task | Est | Status |
|---|---|---|---|
| TF-1 | Toolchain: SDKMAN + Java 21, Maven, nvm + Node LTS, `gh` CLI | 2h | TODO |
| TF-2 | Repo na GitHubie, GitHub Projects board, konwencje branchy i commitów | 2h | TODO |
| TF-3 | Maven multi-module: parent POM + puste moduły serwisów | 3h | TODO |
| TF-4 | **`docker-compose.yml` od zera**: Postgres, Redis, RabbitMQ, MailHog | 4h | TODO |
| TF-5 | GitHub Actions: build + test na każdy push | 3h | TODO |
| TF-6 | README + ADR-0001/0002/0003 | 2h | TODO |

> TF-4 jest kluczowy — piszesz go sam, bez kopiowania. Reszta projektu stoi na tym pliku.

---

## Sprint 1 — catalog-service (~26h)

Cel: pierwszy pełny pion — od encji do działającego endpointu w kontenerze. Bez auth.

| ID | Task | Est | Status |
|---|---|---|---|
| TF-7 | Model domenowy: Event, Venue, SeatMap, Section, Seat, EventSession | 5h | TODO |
| TF-8 | Flyway: migracje + dane seed (przykładowa sala z miejscami) | 4h | TODO |
| TF-9 | REST API: kontrolery, DTO, MapStruct, walidacja (Bean Validation) | 5h | TODO |
| TF-10 | Obsługa błędów: `@RestControllerAdvice` + RFC 7807 `ProblemDetail` | 3h | TODO |
| TF-11 | Testy: unit + `@DataJpaTest` + integracyjne na Testcontainers | 6h | TODO |
| TF-12 | Dockerfile (multi-stage) + wpięcie serwisu w compose | 3h | TODO |

**Pojęcia do opanowania:** encja vs DTO (i dlaczego nigdy nie zwracasz encji z API),
lazy loading, N+1, Testcontainers.

---

## Sprint 2 — Angular od zera (~24h)

Cel: nauka nowego stacku. Osobny sprint, bo to dla ciebie nowy język i framework.

| ID | Task | Est | Status |
|---|---|---|---|
| TF-13 | Angular CLI, struktura projektu, routing, standalone components | 5h | TODO |
| TF-14 | HttpClient, serwisy, typowanie odpowiedzi API, obsługa błędów | 4h | TODO |
| TF-15 | Widoki: lista wydarzeń + strona szczegółów | 6h | TODO |
| TF-16 | **Mapa sali w SVG** — klikalne miejsca, stany (wolne/zajęte/wybrane) | 6h | TODO |
| TF-17 | Dockerfile z nginx + wpięcie w compose | 3h | TODO |

**Pojęcia:** TypeScript (typy, interfejsy, generyki), RxJS Observable vs Promise,
signals, change detection, dlaczego DI w Angularze przypomina to ze Springa.

---

## Sprint 3 — Autentykacja i gateway (~26h)

Cel: zrozumieć JWT od środka, zanim schowasz go za Keycloakiem (ADR-0003).

| ID | Task | Est | Status |
|---|---|---|---|
| TF-18 | identity-service: rejestracja, logowanie, hasła przez BCrypt | 5h | TODO |
| TF-19 | JWT: wystawianie, podpis, walidacja, refresh token | 6h | TODO |
| TF-20 | Spring Security: `SecurityFilterChain`, custom filtr, role | 5h | TODO |
| TF-21 | API Gateway (Spring Cloud Gateway): routing + walidacja tokenu | 5h | TODO |
| TF-22 | Angular: HTTP interceptor, route guard, ekran logowania | 5h | TODO |

**Pułapka:** refresh tokeny i wylogowanie. Zastanów się, co się dzieje, gdy ktoś
ukradnie token — i dlaczego stateless JWT nie da się „unieważnić" bez dodatkowej pracy.

---

## Sprint 4 — booking-service i współbieżność (~24h)

**To jest serce projektu.** Najtrudniejszy i najciekawszy sprint — tu są pytania,
które padają na rozmowach o pracę.

| ID | Task | Est | Status |
|---|---|---|---|
| TF-23 | Model rezerwacji + maszyna stanów (PENDING/CONFIRMED/EXPIRED/CANCELLED) | 4h | TODO |
| TF-24 | Blokada miejsca w Redis z TTL (`SET NX EX`) | 5h | TODO |
| TF-25 | Optimistic locking (`@Version`) + obsługa `OptimisticLockException` | 5h | TODO |
| TF-26 | **Test współbieżności**: 20 wątków walczy o 1 miejsce, dokładnie 1 wygrywa | 5h | TODO |
| TF-27 | Angular: koszyk + timer odliczający do wygaśnięcia rezerwacji | 5h | TODO |

**Pojęcia:** race condition, optimistic vs pessimistic locking, poziomy izolacji
transakcji, dlaczego `synchronized` nie działa gdy masz 3 instancje serwisu.

---

## Sprint 5 — RabbitMQ i notification-service (~20h)

| ID | Task | Est | Status |
|---|---|---|---|
| TF-28 | Topologia Rabbita jako kod: exchange, queue, binding, routing keys | 4h | TODO |
| TF-29 | **Wygasanie rezerwacji przez TTL + Dead Letter Exchange** | 6h | TODO |
| TF-30 | notification-service: konsument zdarzeń, maile, MailHog, szablony | 5h | TODO |
| TF-31 | Retry z backoffem, DLQ, idempotencja konsumenta | 5h | TODO |

**Pojęcia:** at-least-once delivery i dlaczego konsument *musi* być idempotentny,
ack/nack, poison message.

---

## Sprint 6 — Płatności (~28h)

| ID | Task | Est | Status |
|---|---|---|---|
| TF-32 | Stripe test mode, PaymentIntent, klucze poza repo | 5h | TODO |
| TF-33 | Webhooki: weryfikacja podpisu, idempotencja, retry Stripe'a | 6h | TODO |
| TF-34 | **Saga**: rezerwacja → płatność → bilet, z kompensacją | 7h | TODO |
| TF-35 | Angular: Stripe Elements, ekran płatności, obsługa 3D Secure | 5h | TODO |
| TF-36 | Generowanie biletu: PDF + kod QR | 5h | TODO |

**Pułapka:** co się dzieje, gdy Stripe potwierdzi płatność, a twój serwis w tym
momencie padnie? Odpowiedź na to pytanie to cały TF-34.

---

## Sprint 7 — Keycloak (~22h)

| ID | Task | Est | Status |
|---|---|---|---|
| TF-37 | Keycloak w compose, realm jako kod (import JSON) | 5h | TODO |
| TF-38 | Migracja serwisów na OAuth2 Resource Server | 6h | TODO |
| TF-39 | Angular + OIDC (Authorization Code + PKCE) | 5h | TODO |
| TF-40 | Role CUSTOMER/ORGANIZER/ADMIN + panel organizatora | 6h | TODO |

Po tym sprincie napisz ADR podsumowujący: co dała migracja, co było bolesne.
To najlepszy materiał na rozmowę kwalifikacyjną z całego projektu.

---

## Sprint 8 — Obserwowalność i odporność (~19h)

| ID | Task | Est | Status |
|---|---|---|---|
| TF-41 | Actuator + Prometheus + Grafana, dashboard z metrykami biznesowymi | 5h | TODO |
| TF-42 | Distributed tracing (Micrometer Tracing + Zipkin/Tempo) | 5h | TODO |
| TF-43 | Structured logging (JSON) + correlation ID przez wszystkie serwisy | 4h | TODO |
| TF-44 | Resilience4j: circuit breaker, retry, timeout na wywołaniach między serwisami | 5h | TODO |

---

## Sprint 9 — Realtime i finisz (~21h)

| ID | Task | Est | Status |
|---|---|---|---|
| TF-45 | WebSocket: live status miejsc na mapie sali | 6h | TODO |
| TF-46 | Panel organizatora: tworzenie wydarzeń, podgląd sprzedaży | 6h | TODO |
| TF-47 | Testy E2E (Playwright): pełna ścieżka zakupu | 5h | TODO |
| TF-48 | README z diagramami architektury, nagranie demo, deploy | 4h | TODO |

---

## Poza zakresem (świadomie odcięte)

Żeby projekt się skończył, a nie ciągnął w nieskończoność:

- Kafka — RabbitMQ wystarcza do tej domeny (ADR-0002). Ewentualnie później, do analityki.
- Kubernetes — docker-compose starcza. K8s to osobny projekt na CV.
- Service discovery (Eureka) — przy 6 serwisach i compose to niepotrzebna warstwa.
- Zwroty i anulowanie po zakupie, ceny dynamiczne, wielojęzyczność, apka mobilna.
