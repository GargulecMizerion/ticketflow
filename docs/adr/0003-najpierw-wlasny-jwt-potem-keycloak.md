# ADR-0003: Najpierw własny JWT, potem migracja na Keycloak

**Status:** zaakceptowany · 2026-08-31

## Kontekst
Docelowo chcemy Keycloaka (standard w firmach). Ale wrzucenie go od razu oznacza,
że OAuth2/OIDC pozostaje czarną skrzynką — klikasz konfigurację i „działa".

## Decyzja
Sprint 4: własny `identity-service` wystawiający JWT, ręcznie napisany filtr
w Spring Security. Sprint 8: migracja na Keycloaka jako OAuth2 Resource Server.

## Uzasadnienie
Kolejność ma znaczenie dydaktyczne. Po ręcznym napisaniu wystawiania i walidacji
tokenu, konfiguracja Keycloaka przestaje być magią — wiadomo, co robi pod spodem.
Sama migracja jest też realistycznym zadaniem: firmy robią dokładnie taki ruch.

## Konsekwencje
- (−) Podwójna praca nad autoryzacją, ~10h ekstra.
- (+) Historia w gicie pokazuje ewolucję architektury — to dobrze wygląda w portfolio.
- **Ostrzeżenie:** własna implementacja JWT jest **wyłącznie edukacyjna**.
  Nie trafia na produkcję i nie należy jej nigdzie polecać jako wzorca.
