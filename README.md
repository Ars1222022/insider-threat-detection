# Insider Threat Detection – ML-projekt

Ett maskininlärningsprojekt som hittar **insiderhot** i ett sjukvårdssystem.

> **Insiderhot** = någon som har tillgång till systemet på ett legitimt sätt
> (t.ex. är inloggad som vårdpersonal) men använder det för skadliga syften –
> att stjäla patientdata, ändra journaler eller dela sina inloggningar.

**Resultat:** Precision 99,1 % · Recall 96,7 % · F1-score 0,979

📖 **[HANDLEDNING.md](HANDLEDNING.md)** – steg-för-steg-instruktioner och felsökning.

---

## Innehåll

- [Vad du behöver](#vad-du-behöver)
- [Snabbstart](#snabbstart)
- [Projektets 14 steg](#projektets-14-steg)
- [Filerna i projektet](#filerna-i-projektet)
- [Teknologier](#teknologier-vad-är-de-och-varför)
- [Nyckeltal](#nyckeltal)
- [Felsökning](#felsökning)

---

## Vad du behöver

| Tjänst | Vad den är | Kostnad |
|---|---|---|
| **Snowflake** | Databasen där datan ligger | 30 dagar gratis trial |
| **Databricks** | Platsen där modellen tränas | Gratis (Community Edition) |
| **dbt Cloud** | Bygger rena features av rådatan | Gratis (Developer) |
| **Kaggle** | Här laddar du ner datasetet | Gratis |

> **Inget betalkort krävs** för något av dem.

---

## Snabbstart

Notebooken är byggd för **Databricks** (inte Google Colab eller lokal Jupyter).

1. Skapa konton – se [HANDLEDNING.md steg 1–7](HANDLEDNING.md#steg-17--förberedelser).
2. Ladda upp `databricks (steps 8-14)/databricks_steps_8-14.ipynb` till Databricks.
3. Kör cellerna **i ordning, uppifrån och ned**.

> **Inga hemligheter i koden.** Lösenord och API-nycklar matas in när du kör
> cellen, och sparas **aldrig** i filen.

---

## Projektets 14 steg

| Steg | Vad? | Varför? |
|---|---|---|
| 1 | Snowflake-konto | Datan måste ligga i en riktig databas |
| 2 | Databricks-konto | Här tränas modellen |
| 3 | Ladda ner datasetet | Rådatan behövs |
| 4 | Ladda upp till Snowflake | dbt och Databricks läser från Snowflake |
| 5 | Skapa dbt-projekt + koppla till Snowflake | dbt bygger features av rådatan |
| 6 | Skapa dbt-modellerna | Gör om 15 råkolumner till 14 ML-värden |
| 7 | Kör `dbt run` | Skapar tabellerna i Snowflake |
| 8 | Hämta data från Snowflake | Delar upp i features (X) och målvariabel (y) |
| 9 | Sätta upp MLflow | Sparar alla modellkörningar för jämförelse |
| 10 | Träna modellerna | Jämför Isolation Forest mot Random Forest |
| 11 | Spara modellen i MLflow | Slipper träna om – nästa steg laddar den |
| A/B | Jämför två modellversioner | Visar om en ny modell verkligen är bättre |
| 12 | Automatisering + Slack | Fångar försämring automatiskt |
| 13 | Dashboard | Gör historiken synlig i Databricks SQL |
| 14 | Backup av modellen | ZIP med modell + scaler att ladda ner |

**Steg 1–7** görs utanför notebooken (konton + data).
**Steg 8–14** körs i notebooken.
👉 **Alla instruktioner finns i [HANDLEDNING.md](HANDLEDNING.md).**

### Så kopplas tjänsterna ihop

```
Kaggle (CSV) → Snowflake (RAW_ACCESS_LOGS)
                    ↓  dbt bygger om
               FCT_FEATURES (14 features)
                    ↓  notebooken läser
               Databricks (ML-modellen)
                    ↓
               MLflow (sparar modell + Run ID)
```

### Vad de två modellerna gör

| Modell | Bäst för | F1-score |
|---|---|---|
| **Isolation Forest** | Ovanliga attacker den inte visat exempel på | 0,658 |
| **Random Forest** | Vanliga mönster (lär sig av dina exempel) | **0,979** ✅ |

### Viktigaste features

| Feature | Vikt | Betydelse |
|---|---|---|
| `TOTAL_PRIVILEGE_ATTEMPTS` | 46 % | Misslyckade inloggningar + root + su – starkaste varningstecknet |
| `NUM_FAILED_LOGINS` | 30 % | Många misslyckade försök = någon gissar lösenord |

---

## Filerna i projektet

| Fil | Vad den gör |
|---|---|
| `databricks (steps 8-14)/databricks_steps_8-14.ipynb` | **Notebooken** – steg 8–14. Här sker all maskininlärning. |
| `Step 6 (dbt)/models/sources.yml` | Säger **var rådatan finns** i Snowflake. |
| `Step 6 (dbt)/models/staging/stg_raw_logs.sql` | **Rensar** rådatan, lägger till `risk_category`. |
| `Step 6 (dbt)/models/fct_features.sql` | **Bygger features** – de 14 värden modellen tränas på. |
| `Medical_Internal_Attacks_Dataset.csv` | **Rådatan**: 4 000 rader loggar från ett sjukvårdssystem. |
| `databricks (steps 8-14)/feature_importance.csv` | Vilka features som betydde mest. |
| `databricks (steps 8-14)/scaler.pkl` | Sparad skalning av features. |
| `docs/` | Presentationen (PDF + PPTX) och inspelning. |
| `setup_github.ps1` | Laddar upp allt till GitHub. |
| `.gitignore` | Hindrar att hemligheter och utdata laddas upp. |

> **dbt-hållningen:** alla tre dbt-filerna måste ligga **under `models/`**.
> Lägger du dem i projektroten ignorerar dbt dem och `dbt run` svarar med
> *"Compilation Error: source 'snowflake.RAW_ACCESS_LOGS' not found"*.

---

## Teknologier – vad är de och varför

| Verktyg | Vad är det? | Varför just det? |
|---|---|---|
| **Snowflake** | Databas i molnet | Hanterar stora mängder utan att din dator blir långsam |
| **dbt** | Bygger tabeller från SQL | Samma kod kan köras igen – inget handpapperat |
| **Databricks** | Plattform för maskininlärning | Inbyggt MLflow, Spark och dashboards |
| **MLflow** | Loggbok för modellkörningar | Du ser direkt vilken modell som var bäst |
| **scikit-learn** | ML-bibliotek för Python | Branschstandard, gratis, funkar överallt |
| **Groq** | API som ger snabb AI-text | Gratis och väldigt snabbt – bra för rapporttext |
| **Slack** | Chattverktyg | Enklaste sättet att få rapporten till teamet |
| **Git LFS** | Git för stora filer | `.pkl`-filerna ska inte göra repot stort |

---

## Nyckeltal

**Precision** – av de gånger modellen larmar, hur många har den rätt?
Här: 99 av 100 larm är rätta.

**Recall** – av alla verkliga attacker, hur många hittar modellen?
Här: 97 av 100 attacker.

**F1-score** – ett tal som väger precision och recall mot varandra. Här: 0,979.

**Confusion matrix** – i ditt fall: 678 rättiga attacker, 6 falsklarm,
23 missade, 93 korrekt lämnade normala.

> **En ärlig anmärkning:** Eftersom modellerna jämförs på samma testdata
> är 99,1 % inte ett löfte om hur modellen fungerar på nya patienter.
> Använd det som ett resultat på *den här* datamängden.

---

## Felsökning

| Symtom | Orsak | Lösning |
|---|---|---|
| `NameError: X` | Steg 8 har inte körts | Kör steg 8 först |
| `ModuleNotFoundError` | Paket saknas | Kör steg 8 igen – den installerar allt |
| `Compilation Error: source not found` (dbt) | `sources.yml` ligger utanför `models/` | Flytta filen till `models/sources.yml` |
| `dbt run` ger "Completed with N warnings" | Kolumnnamn iSnowflake skiljer sig | Kör `dbt ls` och jämför med `sources.yml` |
| "Experiment saknas" | Fel e-post | Använd samma e-post som i steg 9 |
| "Inga modeller med 14 features" | Fel experimentnamn | Tryck Enter i frågan (standardvärdet är rätt) |
| `Authentication failed` (Snowflake) | Fel inloggning eller warehouse pausad | Starta `COMPUTE_WH` och kontrollera lösenordet |
| `FileNotFoundError` för scaler | Modellen saknar scaler i MLflow | Välj en modell som visar *"[OK] Scaler finns"* |
| Inget händer när du skriver i en cell | Notebooken väntar på svar | Följ frågorna i utskriften – tryck Enter för att hoppa över valfria |
| Kostnader i Snowflake | `COMPUTE_WH` är igång | Manage → Compute → **Suspend** |

---

*Projektet använder datasetet "Medical Internal Attack Detection Dataset" från Kaggle.*

---

## FAQ – vanliga frågor

### Var hittar jag Run ID?

Databricks → vänstermenyn → **Experiment** → `insider_threat_project` →
klicka på din körning → **Run ID**.

### Måste jag använda samma e-post hela tiden?

Ja. Experimentnamnet byggs på e-posten (`/Users/din-epost/...`). Har du använt
en i steg 9 måste du använda samma i steg 11, 12 och 14. MLflow gör versaler till
gemener, så stor/small bokstav spelar ingen roll.

### Kan jag hoppa över Slack och AI-nycklarna?

Ja. Tryck bara Enter när frågan kommer. Koden hoppar då över de delarna och
resten fungerar precis lika bra.

### Koden säger "X har bara 11 features"

Du valde fel tabell i steg 8. Välj `FCT_FEATURES` (14 features), inte
`RAW_ACCESS_LOGS` (11 features).

### Kan jag köra cellerna om?

Ja. Men steg 9–14 behöver variablerna från steg 8 (`X` och `y`). Om du startar
om måste du köra steg 8 igen också.

### Varför sparades ingen `run_id` i CSV-filen?

Det var en bugg: koden frågade efter Run ID *efter* att körningen stängts, och då
är informationen borta. Det är nu rättat – kolumnen fylls i med rätt Run ID.

### Vad är skillnaden mellan modellerna?

**Isolation Forest** hittar det *ovanliga* (oväntat beteende) utan att du behöver
visa exempel. **Random Forest** lär sig dina egna attackmönster. För det här
projektet vinner Random Forest, eftersom attackmönstren är kända i förväg.

### Behöver jag uppdatera några paket?

Nej. Koden installerar själv det den behöver med `%pip install` (t.ex.
`snowflake-connector-python`, `groq`). MLflow, pandas och scikit-learn finns
redan i Databricks.

### Kan jag köra detta utan Databricks?

Tekniskt sett ja, men MLflow-experimenten och Spark-tabellen i steg 13 är byggda
för Databricks. Rekommenderas: kör i Databricks.

### Vad händer när trial-perioden tar slut?

Snowflake: registrera om med samma e-post, så får du nya credits.
dbt: Developer-planen är gratis även efter trial.
Databricks: Community Edition är gratis permanent.
Projektet fortsätter alltså fungera – men kontrollera alltid dina credits.

### Måste jag ladda upp mediafilerna (mp4/m4a) till GitHub?

Nej. De ligger i `docs/` men kan tas bort om du vill ha ett lätt repo – raderna
`*.mp4` och `*.m4a` i `.gitignore` är avkommenterade just för det.

---
---

## Fler frågor?

* **Vanliga frågor och felsökning:** [HANDLEDNING.md](HANDLEDNING.md)
* **Fullständiga steg-för-steg-instruktioner:** [HANDLEDNING.md](HANDLEDNING.md)

---

*Projektet använder datasetet "Medical Internal Attack Detection Dataset" från Kaggle.*
