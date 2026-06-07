CREATE OR REPLACE FUNCTION public.getdobagerangegestationalweek(
    p_dob TIMESTAMP,
    p_dischargedate TIMESTAMP
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_years INT;
BEGIN
    IF (p_dob IS NULL OR p_dischargedate IS NULL) THEN
        RETURN NULL;
    END IF;
    v_years := EXTRACT(YEAR FROM AGE(p_dischargedate, p_dob))::INT;
    IF (v_years < 20) THEN
        RETURN '<20';
    ELSIF (v_years BETWEEN 20 AND 34) THEN
        RETURN '20-34';
    ELSE
        RETURN '>34';
    END IF;
END;
$$;
