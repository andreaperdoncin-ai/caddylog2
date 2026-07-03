# Caddy Log v2.5

Caddy Log è un'applicazione Flutter progettata per il monitoraggio completo dei costi e dei consumi del proprio veicolo. Supporta la gestione di ricariche elettriche (domestiche e pubbliche), rifornimenti di carburante e altre spese ricorrenti o straordinarie.

## Caratteristiche Principali

-   **Dashboard Mensile**: Visualizzazione immediata della spesa totale, energia consumata e litri di carburante per il mese selezionato.
*   **Gestione Ricariche Elettriche**:
    *   **Ricarica Casa**: Calcolo basato sulla tariffa domestica impostata.
    *   **Ricarica Pubblica**: Supporto per diversi gestori con tariffe predefinite personalizzabili.
*   **Gestione Carburante**: Tracciamento dei litri e del costo al litro per rifornimenti di benzina/diesel.
*   **Altre Spese con Logica Avanzata**:
    *   **Autostrada**: Inserimento rapido con competenza mensile.
    *   **Assicurazione & Bollo**: Calcolo automatico della scadenza annuale (+1 anno).
    *   **Tagliando**: Logica di intervallo per spalmare i costi tra l'acquisto o il tagliando precedente e quello attuale.
*   **Statistiche Annuali**: Grafici dettagliati sui trend di consumo, ripartizione delle spese globali e divisione per gestori pubblici.
*   **Interfaccia Intuitiva**: Supporto per gesti swipe per la modifica (sinistra -> destra) e l'eliminazione (destra -> sinistra) rapida dei record.
*   **Sincronizzazione Cloud**: Integrazione con Firebase Firestore per la persistenza dei dati in tempo reale.

## Struttura del Progetto

-   `lib/state/app_state.dart`: Gestione dello stato globale e interazione con Firebase.
-   `lib/views/`: Schermate principali (Home, Elettrico, Benzina, Altre Spese, Statistiche, Opzioni).
-   `lib/widgets/`: Componenti UI riutilizzabili, incluso il foglio di inserimento spese dinamico.

## Build

Per generare l'APK leggero ottimizzato per l'architettura dei dispositivi:

```bash
flutter build apk --split-per-abi
```
