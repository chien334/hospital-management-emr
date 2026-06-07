CREATE OR REPLACE FUNCTION fn_acc_get_reverse_transaction_records()
RETURNS TABLE (
    reversetransactionid INT,
    transactiondate TIMESTAMP,
    sectionid INT,
    tuid INT,
    fiscalyearid INT,
    reason VARCHAR,
    createdon TIMESTAMP,
    createdby INT,
    reversedon TIMESTAMP,
    reversedby INT,
    hospitalid INT,
    vouchernumber VARCHAR,
    voucherid INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.reversetransactionid,
        r.transactiondate,
        (j.item->>'SectionId')::INT AS sectionid,
        r.tuid,
        r.fiscalyearid,
        r.reason,
        (j.item->>'CreatedOn')::TIMESTAMP AS createdon,
        (j.item->>'CreatedBy')::INT AS createdby,
        r.createdon AS reversedon,
        r.createdby AS reversedby,
        r.hospitalid,
        j.item->>'VoucherNumber' AS vouchernumber,
        (j.item->>'VoucherId')::INT AS voucherid
    FROM acc_reversetransaction r
    CROSS JOIN LATERAL json_array_elements(r.jsondata::json) WITH ORDINALITY AS j(item, ord)
    WHERE j.ord = 1;
END;
$$ LANGUAGE plpgsql;
