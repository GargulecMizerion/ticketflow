# ADR-0001: Mikroserwisy zamiast monolitu

**Status:** zaakceptowany · 2026-08-31

## Kontekst
Projekt edukacyjny/portfolio. Domena (sprzedaż biletów) spokojnie zmieściłaby się
w dobrze zbudowanym monolicie modularnym.

## Decyzja
Sześć osobnych serwisów: gateway, identity, catalog, booking, payment, notification.

## Uzasadnienie
Cel projektu to **nauka i portfolio**, nie minimalizacja kosztu utrzymania.
Monolit nie zmusiłby do zmierzenia się z: komunikacją asynchroniczną, transakcjami
rozproszonymi, distributed tracingiem, wersjonowaniem kontraktów. To są dokładnie te
tematy, o które pytają na rozmowach.

## Konsekwencje
- (−) Więcej boilerplate'u, wolniejszy start, trudniejszy debugging.
- (−) Trzeba świadomie rozwiązać spójność danych (patrz saga, TF-34).
- (+) Każdy serwis jest mały, więc pojedynczy task jest ogarnialny w jedną sesję.
- **Uczciwa uwaga:** w prawdziwej firmie z tym zakresem zacząłbym od monolitu
  modularnego. Jeśli ktoś zapyta o to na rozmowie — to jest właściwa odpowiedź.
