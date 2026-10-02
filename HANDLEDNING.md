# Handledning – Insider Threat Detection

Steg-för-steg-instruktioner för hela projektet. Allt här är kontrollerat mot
den faktiska koden och mot officiell dokumentation för Snowflake, Databricks
och dbt.

👉 **[Tillbaka till README](README.md)**

---

## Innehåll

- [Steg 1–7 – Förberedelser](#steg-17-förberedelser)
- [Steg 8–14 – Notebooken](#steg-814-notebooken)
- [Teknologier](#teknologier-vad-är-de-och-varför)
- [Begrepp](#begrepp-du-behöver-känna-till)
- [FAQ](#faq-vanliga-frågor)
- [Felsökning](#felsökning)

---

## Steg 1–7 – Förberedelser

Steg 1–7 görs **utanför notebooken** (du skapar konton och laddar upp data).
Steg 8–14 körs i notebooken – se avsnittet nedan.

|---|---|---|
| 1 | Snowflake-konto | Datan måste ligga i en riktig databas |
| 2 | Databricks-konto | Här tränas modellen |
| 3 | Ladda ner datasetet | Rådatan behövs |
| 4 | Ladda upp till Snowflake | dbt och Databricks läser från Snowflake |
| 5 | Skapa dbt-projekt + koppla till Snowflake | dbt bygger features av rådatan |
| 6 | Skapa dbt-modellerna | Gör om 15 råkolumner till 14 ML-värden |
| 7 | Kör `dbt run` | Skapar tabellerna i Snowflake |
| 8–14 | Notebooken | Tränar, sparar, jämför och exporterar modellen |

---

### Steg 1 – Skapa Snowflake-konto

**Vad?** Snowflake är en databas i molnet. All rådata och alla färdiga features
ligger där.

**Varför?** En vanlig fil fungerar inte när flera ska arbeta med samma data, och
den klarar inte stora mängder. Snowflake klarar terabytes.

**Hur?**
1. Gå till [snowflake.com](https://www.snowflake.com) och klicka **Free Trial**.
2. Fyll i namn, e-post och jobb. Roll: *Data Engineer* eller *Student*.
   Företag: skriv *Self Employed* eller *Student*.
3. Välj **Enterprise Edition** – ger tillgång till funktioner som saknas i Standard.
4. Välj molnleverantör (t.ex. **Microsoft Azure**) och region nära dig
   (t.ex. *Sweden Central* eller *North Europe*).
5. Bekräfta att du är människa, verifiera e-posten och aktivera kontot.
6. Skapa användarnamn och lösenord.
7. **Inget betalkort krävs.** Du får en kreditudgift att använda i 30 dagar.

> **Notera dina uppgifter** – du behöver dem senare: *Account*
> (t.ex. `RQKXOYX-PV94267`), *Användarnamn* och *Lösenord*.
> Du hittar dem i Snowflake under **Manage → Account**.

> **Tips:** Starta virtual warehouse **COMPUTE_WH** (Manage → Compute → Start)
> varje gång du börjar – den kostar credits när den är igång.

---

### Steg 2 – Skapa Databricks-konto

**Vad?** Databricks är plattformen där du tränar modellen. Den har MLflow inbyggt.

**Varför?** Där kan du träna modeller, jämföra körningar och bygga dashboards
utan att installera något lokalt.

**Hur?**
1. Gå till [community.cloud.databricks.com](https://community.cloud.databricks.com)
   och klicka **Sign up** (eller **Get started free**).
2. Registrera med e-post – **inget betalkort krävs**.
3. Logga in. Du hamnar i en workspace där du kan skapa notebooks.
4. Skapa en notebook och byt språk till **Python** om den inte redan är det.

> **Tips:** Pausa datorn (Compute → din cluster → *Terminate*) när du är klar
> för dagen, så slutar den kosta credits.

---

### Steg 3 – Ladda ner datasetet

**Vad?** 4 000 rader loggar från ett sjukvårdssystem, med en kolumn som anger
om raden var en attack eller normalt beteende.

**Varför?** Du behöver verklig data för att kunna träna – meningsfull data, inte
uppfinna siffror.

**Hur?**
1. Gå till [Kaggle](https://www.kaggle.com) och skapa ett gratis konto.
2. Sök efter **Medical Internal Attack Detection Dataset**.
3. Klicka **Download** på filen `.csv` (cirka 300 KB).
4. Spara den som `Medical_Internal_Attacks_Dataset.csv` i projektmappen.

---

### Steg 4 – Ladda upp data till Snowflake

**Vad?** CSV-filen görs om till en riktig tabell i Snowflake, som heter
`RAW_ACCESS_LOGS` och ligger i databasen `INSIDER_THREAT_DB`.

**Varför?** dbt och Databricks kan bara läsa data som ligger i en databas – inte
från en fil på din dator.

**Hur?**
1. Logga in på Snowflake och se till att **COMPUTE_WH** är igång.
2. Välj **Databases → INSIDER_THREAT_DB → PUBLIC → Tables**.
3. Klicka **+ Create table** (eller *Upload local files*).
4. Namnge tabellen `RAW_ACCESS_LOGS`.
5. Dra in CSV-filen och klicka **Create**.
6. Verifiera med SQL i ett *Worksheet*:

```sql
SELECT COUNT(*) FROM INSIDER_THREAT_DB.PUBLIC.RAW_ACCESS_LOGS;
```

Svaret ska vara **4000**.

> **Tips:** Pausa `COMPUTE_WH` när du är klar – annars fortsätter den kosta credits.

---

### Steg 5 – Skapa dbt-projekt och koppla det till Snowflake

**Vad?** dbt är ett verktyg som bygger nya tabeller utifrån dina gamla, med
vanlig SQL. Du skapar ett projekt och kopplar det till Snowflake.

**Varför?** Utan dbt skulle du behöva skriva om samma SQL manuellt varje gång
datat ändrades. Med dbt kör du samma kod igen och igen – och vet att den ger
samma resultat.

**Hur?**
1. Gå till [getdbt.com](https://www.getdbt.com) och skapa konto.
   Välj **Developer**-planen (gratis: 1 projekt, 1 användare, 3 000 modeller/mån).
2. Verifiera e-posten.
3. **New Project** → döp till `insider_threat_project` → **Continue**.
4. Under *Connection settings* välj **Snowflake**.
5. Fyll i uppgifterna – samma som i steg 1:

| Fält | Vad du skriver |
|---|---|
| Account | Din Snowflake account, t.ex. `RQKXOYX-PV94267` |
| User | Ditt användarnamn i Snowflake |
| Password | Ditt Snowflake-lösenord |
| Database | `INSIDER_THREAT_DB` |
| Warehouse | `COMPUTE_WH` |
| Schema | Lämna tomt nu, eller `PUBLIC` |

6. Klicka **Test connection** → du ska se *Success*.
7. **Save** och välj **Managed** när den frågar efter repository –
   dbt skapar då ett Git-repository åt dig automatiskt.

> **Så här kopplas tjänsterna ihop:**
>
> ```
> Kaggle (CSV-fil)
>      │  laddas upp
>      ▼
> Snowflake  ──── RAW_ACCESS_LOGS (rådata)
>      │        dbt läser och bygger om
>      │           ▼
>      └────── FCT_FEATURES (14 features)
>                  │  notebooken läser
>                  ▼
>        Databricks (ML-modellen tränas)
>                  │
>                  ▼
>        MLflow (sparar modellen + Run ID)
> ```

---

### Steg 6 – Skapa dbt-modellerna

**Vad?** Tre filer som gör om rådatan till något maskininlärning kan använda.

| Fil | Vad den gör |
|---|---|
| `models/sources.yml` | Säger **var** rådatan finns |
| `models/staging/stg_raw_logs.sql` | **Rensar** datan och skapar `risk_category` |
| `models/fct_features.sql` | **Bygger features** – de 14 siffrorna ML-modellen tränas på |

**Varför?** Rådatan innehåller text som en modell inte förstår (t.ex.
`unauthorized_access`), och sakkar vissa värden modellen behöver. dbt gör om
detta automatiskt – varje gång du kör den.

**Hur?** Skapa filerna i dbt-projektet, i mappen `models/`:

```
models/
├── sources.yml
├── fct_features.sql
└── staging/
    └── stg_raw_logs.sql
```

Filerna finns i `Step 6 (dbt)/models/` i det här projektet – klistra bara in
innehållet. **Spara efter varje fil** (Ctrl+S).

> **Varför just denna struktur?** dbt hittar bara filer under `models/`.
> `staging/`-mappen är bara en konvention – dbt hittar även filer där,
> eftersom den ligger under `models/`.

---

### Steg 7 – Kör dbt-transformationerna

**Vad?** Kör `dbt run` – då skapar dbt de nya tabellerna i Snowflake.

**Varför?** Innan detta kommandot finns det bara din rådata. Efteråt finns det
även `FCT_FEATURES` – tabellen med de 14 features som notebooken behöver.

**Hur?**
1. Öppna **Commands** (fliken längst ner i dbt Cloud).
2. Skriv:

```
dbt run
```

3. Du ska se `Completed successfully` och `PASS=2`.
4. Verifiera i Snowflake att det blev 4 000 rader:

```sql
USE SCHEMA INSIDER_THREAT_DB.PUBLIC;
SELECT COUNT(*) FROM FCT_FEATURES;
```

> **Kommandon du kommer att använda:**
>
> | Kommando | Vad det gör |
> |---|---|
> | `dbt run` | Bygger alla modeller |
> | `dbt run --select fct_features` | Bygger bara huvudmodellen |
> | `dbt ls` | Listar alla modeller i projektet |

---

---

## Steg 8–14 – Notebooken

### Steg 8 – Hämta data från Snowflake

**Vad?** Koden ansluter till Snowflake, läser in tabellen `FCT_FEATURES` och
delar upp den i `X` (features – det modellen lär sig från) och `y` (målvariabel –
det modellen ska förutsäga).

**Varför?** Maskininlärningsmodeller kan bara använda **siffror**. Därför behöver
kolumnerna `attack_type` och `risk_category` uteslutas, och det nya värdet
`total_privilege_attempts` räknas fram.

**Hur?** Kör cellen och fyll i dina Snowflake-uppgifter (från steg 1). Välj
`FCT_FEATURES` – ordet betyder "faktatabell", alltså den med färdiga features.

Kontrollera i utskriften att det står:
- ✅ *"X har 14 features"* (inte 11)
- ✅ *"4 000 rader"*
- ✅ *"Attack-rate: 87.6%"*

> **Vanligt fel:** Väljer du `RAW_ACCESS_LOGS` får du bara 11 features i stället
> för 14. Koden varnar dig och berättar vad som är fel.

---

### Steg 9 – Sätta upp MLflow

**Vad?** MLflow är ett "laboratoryckel" för maskininlärning. Det sparar alla
dina modellkörningar så att du kan jämföra dem i efterhand.

**Varför?** Utan MLflow är det lätt att glömma bort vilken modell som gav bäst
resultat. Med MLflow ser du direkt att din bästa modell gav F1 = 0,979.

**Hur?** Ange din e-postadress. Koden skapar ett experiment som heter
`/Users/din-epost/insider_threat_project`. Du hittar det i Databricks under
**Experiment** i vänstermenyn.

---

### Steg 10 – Träna modellerna

**Vad?** Koden tränar och jämför **två** modeller:

| Modell | Hur den fungerar | Bäst för |
|---|---|---|
| **Isolation Forest** | Lägger "isolerade" punkter i en skog och markerar avvikelser | Ovanliga attacker (den hittar det du inte visat) |
| **Random Forest** | Bygger många beslutsträd och röstar om dem | Vanliga mönster (den lär sig av dina exempel) |

**Varför?** Ingen modell är bäst på allt. Genom att testa båda ser du vilken som
passar just din data. Här vinner Random Forest (F1 0,979 mot 0,658).

**Hur?** Koden delar automatiskt upp datan i 80 % träning och 20 % test, testar
flera inställningar och väljer den bästa. Testdatan används aldrig i träningen.

> **Ett noggrant råd:** Eftersom de två modellerna jämförs på samma testdata
> vinner den som är bäst på just det datamängden. Använd därför **inte**
> testresultatet som ett löfte om hur modellen fungerar på nya patienter.

---

### Steg 11 – Spara modellen i MLflow

**Vad?** Loggar den bästa modellen tillsammans med sina inställningar,
prestandamått och en fil med vilka features som betyder mest.

**Varför?** Så att du inte behöver träna om modellen varje gång. Steg 12–14 laddar
den sparade modellen i stället för att träna ny.

**Viktigaste features i din modell:**

| Feature | Vikt | Betydelse |
|---|---|---|
| `TOTAL_PRIVILEGE_ATTEMPTS` | 46 % | Misslyckade inloggningar + root + su – det starkaste varningstecknet |
| `NUM_FAILED_LOGINS` | 30 % | Många misslyckade försök = någon gissar lösenord |
| `ROOT_SHELL` | 4 % | Åtkomst som administratör |

**Hur?** Ange samma e-post som i steg 9. Kopiera sedan **Run ID** från MLflow –
det är det unika id:t som nästa steg behöver.

---

### A/B-test – jämför två modellversioner

**Vad?** En cell som jämför en *baseline*-modell (Version A) mot en ny modell
(Version B), först på testdata och sedan i en simulerad "riktig" trafik.

**Varför?** När du byter till en ny modell vet du inte om den faktiskt är bättre
– bara att den är ny. Det är precis så här Netflix och Uber testar sina
modellversioner innan de släpper ut dem till alla användare.

**Hur?** Kör cellen och välj två körningar ur listan (välj bara modeller som
visar **14 features**). Koden gör sedan två saker:

1. **Offline-jämförelse** – båda modellerna testar på *samma* testdata, så
   jämförelsen blir rättvis.
2. **Live A/B-test (valfritt)** – du kan svara `ja` när du blir frågad. Koden
   skickar då 70 % av användarna till A och 30 % till B, med så kallad
   *hash-routing*: samma användare får alltid samma modell, så att en person
   inte byter modell mellan två besök.

> **Obs:** Exakta siffror varierar något mellan körningar, eftersom de bygger på
> vilka användare som hamnar i varje grupp. Slutsatsen blir densamma: den
> bättre modellen vinner, och det är den du behåller.

---

### Steg 12 – Automatisering med Slack och AI

**Vad?** Ett övervakningsskript som mäter modellens prestanda, jämför med
tidigare körningar, skickar rapport till Slack och sparar allt i MLflow och CSV.

**Varför?** En modell kan försämras utan att du märker det – till exempel om
patientbeteenden förändras. Automatisk övervakning fångar det direkt.

**Hur?** Välj **1** för att träna en ny modell (du får välja antal träd och
djup), eller **2** för att ladda en befintlig från MLflow. Nycklarna
(Slack-webhook, Groq) är **valfria** – tryck Enter för att hoppa över dem.

---

### Steg 13 – Dashboard

**Vad?** Gör om CSV-historiken till en riktig tabell i Databricks, så att du kan
bygga diagram i Databricks SQL.

**Varför?** CSV-filer är bra för backup men svåra att visualisera. En tabell kan
användas direkt i dashboards.

**Hur?** Kör cellen, ange ett tabellnamn och en e-post. Kopiera sedan den SQL-fråga
som skrivs ut och klistra in den i Databricks SQL.

---

### Steg 14 – Backup av modellen

**Vad?** Laddar ner modellen från MLflow och packar den i ett ZIP med modell,
scaler och en README.

**Varför?** MLflow ligger i molnet. Om du förlorar åtkomst till kontot har du
fortfarande modellen lokalt – och kan visa den för en arbetsgivare.

**Hur?** Välj modell (välj gärna en som visar *"[OK] Scaler finns, 14 features"*),
klicka på den gröna knappen för att ladda ner, och packa upp ZIP-filen.

---

---

## Teknologier – vad är de och varför

| Verktyg | Vad är det? | Varför just det? |
|---|---|---|
| **Snowflake** | Databas i molnet | Hanterar stora datamängder utan att din dator blir långsam |
| **dbt** | Verktyg som bygger tabeller från SQL | Samma kod kan köras igen och igen – inget handpapperat |
| **Databricks** | Plattform för maskininlärning | Inbyggt MLflow, Spark och dashboards på ett ställe |
| **MLflow** | Loggbok för modellkörningar | Du ser direkt vilken modell som var bäst |
| **scikit-learn** | Bibliotek för ML i Python | Branschstandard, gratis, funkar överallt |
| **Groq** | API som ger snabb AI-text | Gratis och väldigt snabbt – bra för rapporttext |
| **Slack** | Chattverktyg | Enklaste sättet att få rapporten till teamet |
| **Git LFS** | Git för stora filer | `.pkl`-filerna ska inte göra repot stort |

---

## Begrepp du behöver känna till

**Feature** – en egenskap hos datan som modellen tittar på.
T.ex. "antal misslyckade inloggningar".

**Målvariabel** – det modellen ska förutsäga. Här: är detta en attack eller
normalt beteende?

**Träningsdata / testdata** – modellen tränas på det ena och *granskas* på det
andra. Testdatan får den aldrig se under träningen, annars blir resultatet
vilseledande.

**Precision** – av de gånger modellen larmar, hur många gånger har den rätt?
Här: av 100 larm är 99 rätta. *(Falsklarm = 1 av 100.)*

**Recall** – av alla verkliga attacker, hur många hittar modellen?
Här: av 100 attacker hittar den 97. *(Missade attacker = 3 av 100.)*

---

## Felsökning

| Symtom | Orsak | Lösning |
|---|---|---|
| `NameError: X` | Steg 8 har inte körts | Kör steg 8 först |
| `ModuleNotFoundError` | Paket saknas | Kör steg 8 igen – den installerar allt |
| "Experiment saknas" | Fel e-post | Använd samma e-post som i steg 9 |
| "Inga modeller med 14 features" | Fel experimentnamn | Tryck Enter i frågan (standardvärdet är rätt) |
| "Authentication failed" (Snowflake) | Fel inloggning | Kontrollera att warehouse är **startad** i Snowflake |
| `FileNotFoundError` för scaler | Modellen saknar scaler i MLflow | Välj en modell som visar *"[OK] Scaler finns"* |
| `Compilation Error: source not found` (dbt) | `sources.yml` ligger utanför `models/` | Flytta filen till `models/sources.yml` |

---

*Projektet använder datasetet "Medical Internal Attack Detection Dataset" från Kaggle.*


**F1-score** – ett enda tal som väger precision och recall mot varandra.
Här: 0,979 – nästan perfekt i båda.

**Confusion matrix** – en tabell med fyra rutor: rätt/sant, rätt/falskt, fel/sant
och fel/falskt. I ditt fall: 678 rättiga attacker, 6 falsklarm, 23 missade och
93 korrekt lämnade normala.

**Scaler** – gör värdena jämförbara. Utan den skulle "1 000 000 bytes" väga
tyngre än "5 inloggningar" bara för att talet är större.

**Run ID** – MLflow:s unika id för varje körning. Behövs för att hämta
rätt modell senare.

**Artifact** – en fil som hör till en körning (t.ex. modellen eller scalern).

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

### Måste jag ladda upp mediafilerna (mp4/m4a) till GitHub?

Nej. De ligger i `docs/` men kan tas bort om du vill ha ett lätt repo – raderna
`*.mp4` och `*.m4a` i `.gitignore` är avkommenterade just för det.

---

