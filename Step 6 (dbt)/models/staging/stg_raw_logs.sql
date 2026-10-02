-- =============================================
-- STAGING MODELL: Rensar och standardiserar rådata
-- =============================================
-- Syfte: Förbereda rådata för ML-modellen
-- Tabellkälla: INSIDER_THREAT_DB.PUBLIC.RAW_ACCESS_LOGS
-- Antal rader efter transformation: 4 000 (oförändrat)
-- 
-- Vad den gör:
-- 1. Skapar en unik användaridentifierare (user_session_id)
-- 2. Behåller alla originalkolumner
-- 3. Lägger till en kategori för risk (high_risk/normal/unknown)
-- 4. Lägger till en tidsstämpel för spårbarhet
-- =============================================

SELECT 
    -- SKAPA UNIK IDENTIFIERARE
    -- Slår ihop protokoll och tjänst till en nyckel (t.ex. "EHR_patient_records")
    CONCAT(protocol_type, '_', service) AS user_session_id,
    
    -- ORIGINALKOLUMNER (behålls oförändrade)
    attack_type,                -- Målvariabel för ML (normal, unauthorized_access, etc.)
    num_failed_logins,          -- Antal misslyckade inloggningar
    root_shell,                 -- Root-åtkomst (1=ja, 0=nej)
    su_attempted,               -- Privilegieeskaleringsförsök (1=ja, 0=nej)
    num_access_files,           -- Antal åtkomster till patientjournaler/filer
    num_file_creations,         -- Antal skapade filer
    src_bytes,                  -- Skickad data (bytes)
    dst_bytes,                  -- Mottagen data (bytes)
    duration,                   -- Sessionlängd i sekunder
    same_srv_rate,              -- Andel åtkomst till samma tjänst (0-1)
    diff_srv_rate,              -- Andel åtkomst till olika tjänster (0-1)
    flag,                       -- Statusflagga (SF=normal, REJ=avvisad, S0=fel)
    logged_in,                  -- Inloggningsstatus (1=inloggad, 0=inte)
    
    -- BERÄKNADE FÄLT (för enklare analys)
    -- Kategoriserar risk baserat på flagga
    CASE 
        WHEN flag IN ('REJ', 'S0') THEN 'high_risk'   -- Avvisad eller fel → hög risk
        WHEN flag = 'SF' THEN 'normal'                -- Normal flagga → normal risk
        ELSE 'unknown'                                -- Okänd flagga
    END AS risk_category,
    
    -- METADATA (för spårbarhet)
    CURRENT_TIMESTAMP() AS processed_at  -- När raden bearbetades

FROM {{ source('snowflake', 'RAW_ACCESS_LOGS') }}
-- Källa: INSIDER_THREAT_DB.PUBLIC.RAW_ACCESS_LOGS (4 000 rader)