# ADR-0002: RabbitMQ zamiast Kafki

**Status:** zaakceptowany · 2026-08-31

## Kontekst
Potrzebujemy brokera do: wygaszania rezerwacji po 10 minutach, wysyłki maili,
przetwarzania webhooków płatniczych.

## Rozważane opcje

**Kafka** — log zdarzeń, świetna do dużego przepływu i replayu historii.
Ale: brak natywnych opóźnionych wiadomości (trzeba obejść przez topic z opóźnieniem
albo scheduler), brak per-message routingu, cięższa lokalnie.

**RabbitMQ** — kolejka z routingiem. TTL + Dead Letter Exchange dają opóźnione
wiadomości praktycznie za darmo, co jest dokładnie mechanizmem wygaszania rezerwacji.

## Decyzja
RabbitMQ.

## Uzasadnienie
Nasz główny use case to *opóźniona wiadomość dla konkretnej rezerwacji* — wzorzec,
w którym Rabbit jest naturalny, a Kafka wymaga obejścia. Dodatkowo Kayman ma już
podstawy Rabbita, więc krzywa wejścia jest łagodniejsza.

## Konsekwencje
- Brak replayu historii zdarzeń — akceptowalne, nie budujemy event sourcingu.
- Jeśli później pojawi się potrzeba analityki/strumieniowania, Kafkę można dołożyć
  obok jako osobny kanał. Nie zamykamy sobie tej drogi.
