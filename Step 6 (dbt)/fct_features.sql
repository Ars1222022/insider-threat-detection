-- =============================================
-- HUVUDMODELL FÖR ML: Features för Insider Threat Detection
-- =============================================
-- Syfte: Skapa en färdig feature-tabell för maskininlärning
-- Källa: stg_raw_logs (staging-modellen ovan)
-- Antal rader: 4 000 (oförändrat)
--
-- Vad den gör:
-- 1. Använder den rensade datan från staging
-- 2. Beräknar extra features (total_privilege_attempts, etc.)
-- 3. Behåller risk_category från staging
-- 4. Skapar en numerisk flag_risk_score för ML-algoritmer
-- =============================================

SELECT 
    -- IDENTIFIERARE (används för att koppla ihop rader)
    user_session_id,            -- Unik nyckel (t.ex. "EHR_patient_records")
    
    -- MÅLVARIABEL (det ML-modellen ska förutsäga)
    attack_type,                -- normal, unauthorized_access, credential_sharing, etc.
    
    -- ORIGINALFEATURES (från staging)
    num_failed_logins,          -- Misslyckade inloggningar
    root_shell,                 -- Root-åtkomst
    su_attempted,               -- Privilegieeskaleringsförsök
    num_access_files,           -- Åtkomst till filer
    num_file_creations,         -- Skapade filer
    src_bytes,                  -- Skickad data
    dst_bytes,                  -- Mottagen data
    duration,                   -- Sessionlängd
    same_srv_rate,              -- Samma tjänst-frekvens
    diff_srv_rate,              -- Olika tjänster-frekvens
    flag,                       -- Statusflagga
    logged_in,                  -- Inloggningsstatus
    
    -- BERÄKNADE FEATURES (för ML-modellen)
    -- Summerar alla privilegieförsök till ett enda mått
    (num_failed_logins + root_shell + su_attempted) AS total_privilege_attempts,
    
    -- Summerar total dataöverföring (in + ut)
    (src_bytes + dst_bytes) AS total_bytes_transferred,
    
    -- KATEGORISKA FEATURES (från staging)
    risk_category,              -- 'high_risk', 'normal', 'unknown'
    
    -- NUMERISK RISKSCORE (för ML-algoritmer som kräver siffror)
    CASE 
        WHEN flag IN ('REJ', 'S0') THEN 2   -- Hög risk
        ELSE 0                               -- Låg risk
    END AS flag_risk_score

FROM {{ ref('stg_raw_logs') }}
-- Källa: stg_raw_logs (4 000 rader, ingen CROSS JOIN)