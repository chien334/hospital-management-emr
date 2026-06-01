CREATE OR REPLACE FUNCTION fn_acc_getnamebycode(
    p_code VARCHAR(200),
    p_hospitalid INT
)
RETURNS VARCHAR(400) AS $$
DECLARE
    v_retstringname VARCHAR(400) := '';
    v_type VARCHAR(100);
    v_name VARCHAR(400);
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "ACC_MST_CodeDetails" 
        WHERE "HospitalId" = p_hospitalid AND "Code" = p_code 
        LIMIT 1
    ) THEN
        SELECT "Description", "Name" INTO v_type, v_name
        FROM "ACC_MST_CodeDetails"
        WHERE "HospitalId" = p_hospitalid AND "Code" = p_code
        LIMIT 1;

        v_retstringname := CASE v_type
            WHEN 'PrimaryGroup' THEN (
                SELECT "PrimaryGroupName" 
                FROM "ACC_MST_PrimaryGroup" 
                WHERE "PrimaryGroupCode" = v_name 
                LIMIT 1
            )
            WHEN 'COA' THEN (
                SELECT "ChartOfAccountName" 
                FROM "ACC_MST_ChartOfAccounts" 
                WHERE "COACode" = v_name 
                LIMIT 1
            )
            WHEN 'LedgerGroup' THEN (
                SELECT "LedgerGroupName" 
                FROM "ACC_MST_LedgerGroup" 
                WHERE "Name" = v_name AND "HospitalId" = p_hospitalid 
                LIMIT 1
            )
            WHEN 'LedgerName' THEN (
                SELECT "LedgerName" 
                FROM "ACC_Ledger" 
                WHERE "Name" = v_name AND "HospitalId" = p_hospitalid 
                LIMIT 1
            )
            ELSE ''
        END;
    END IF;

    RETURN COALESCE(v_retstringname, '');
END;
$$ LANGUAGE plpgsql;
