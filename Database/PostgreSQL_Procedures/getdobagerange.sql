CREATE OR REPLACE FUNCTION public.getdobagerange(
    p_dob TIMESTAMP,
    p_visitdate TIMESTAMP
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_years INT;
BEGIN
    IF (p_dob IS NULL OR p_visitdate IS NULL) THEN
        RETURN NULL;
    END IF;
    v_years := EXTRACT(YEAR FROM AGE(p_visitdate, p_dob))::INT;
    IF (v_years BETWEEN 0 AND 9) THEN
        RETURN '0-9 Years';
    ELSIF (v_years BETWEEN 10 AND 14) THEN
        RETURN '10-14 Years';
    ELSIF (v_years BETWEEN 15 AND 19) THEN
        RETURN '15-19 Years';
    ELSIF (v_years BETWEEN 20 AND 59) THEN
        RETURN '20-59 Years';
    ELSIF (v_years BETWEEN 60 AND 69) THEN
        RETURN '60-69 Years';
    ELSIF (v_years >= 70) THEN
        RETURN '>=70 Years';
    ELSE
        RETURN 'Others';
    END IF;
END;
$$;
