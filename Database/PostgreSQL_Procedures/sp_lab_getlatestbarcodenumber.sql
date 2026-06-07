CREATE OR REPLACE FUNCTION sp_lab_getlatestbarcodenumber(

)
RETURNS TABLE (
    "Value" DECIMAL
) AS $$
BEGIN
    
    RETURN QUERY SELECT coalesce(max(barcodenumber)||1,1000000) AS "Value" from lab_barcode;
END;
$$ LANGUAGE plpgsql;