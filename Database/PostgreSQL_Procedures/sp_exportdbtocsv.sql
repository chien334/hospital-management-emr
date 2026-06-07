CREATE OR REPLACE FUNCTION sp_exportdbtocsv()
RETURNS TABLE (
    "v_resultstatus" VARCHAR
) AS $$
BEGIN
    RETURN QUERY SELECT 'success'::VARCHAR;
END;
$$ LANGUAGE plpgsql;