CREATE OR REPLACE FUNCTION public.getdobagerangeinpatientoutcome(
    p_dob TIMESTAMP,
    p_dischargedate TIMESTAMP
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_days INT;
    v_years INT;
BEGIN
    IF (p_dob IS NULL OR p_dischargedate IS NULL) THEN
        RETURN NULL;
    END IF;

    v_days := p_dischargedate::DATE - p_dob::DATE;
    v_years := EXTRACT(YEAR FROM AGE(p_dischargedate, p_dob))::INT;

    IF (v_days BETWEEN 0 AND 7) THEN
        RETURN '0-7Days';
    ELSIF (v_days BETWEEN 8 AND 28) THEN
        RETURN '8-28Days';
    ELSIF (v_days > 28 AND v_years < 1) THEN
        RETURN '29Days-1Year';
    ELSIF (v_years BETWEEN 1 AND 4) THEN
        RETURN '01-04Years';
    ELSIF (v_years BETWEEN 5 AND 14) THEN
        RETURN '05-14Years';
    ELSIF (v_years BETWEEN 15 AND 19) THEN
        RETURN '15-19Years';
    ELSIF (v_years BETWEEN 20 AND 29) THEN
        RETURN '20-29Years';
    ELSIF (v_years BETWEEN 30 AND 39) THEN
        RETURN '30-39Years';
    ELSIF (v_years BETWEEN 40 AND 49) THEN
        RETURN '40-49Years';
    ELSIF (v_years BETWEEN 50 AND 59) THEN
        RETURN '50-59Years';
    ELSIF (v_years BETWEEN 60 AND 69) THEN
        RETURN '60-69Years';
    ELSIF (v_years >= 70) THEN
        RETURN '>=70Years';
    ELSE
        RETURN 'Others';
    END IF;
END;
$$;
