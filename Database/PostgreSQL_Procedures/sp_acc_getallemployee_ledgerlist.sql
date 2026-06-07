/* ***********************************************************************
FileName: [SP_ACC_GetAllEmployee_LedgerList]  
CreatedBy/date: Anish/Apr-2020
Description: To get ledger details for Consultant ledgers from acc-mapping table 
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud/Nagesh:20Jun'20                    HospitalId added for Phrm-Acc Separation
************************************************************************ */
CREATE OR REPLACE FUNCTION sp_acc_getallemployee_ledgerlist(
    p_hospitalid INT
)
RETURNS TABLE (
    "LedgerId" INT,
    "EmployeeId" INT,
    "LedgerName" VARCHAR,
    "LedgerCode" VARCHAR,
    "LedgerGroupName" VARCHAR
) AS $$
BEGIN
    
      RETURN QUERY SELECT led.ledgerid, consledmap.referenceid AS "EmployeeId",
      led.ledgername, led.code AS "LedgerCode", ledgrp.ledgergroupname
      from acc_ledger led, acc_mst_ledgergroup ledgrp, 
      (select * from acc_ledger_mapping where ledgertype='consultant' and hospitalid=p_hospitalid) consledmap
      where led.ledgergroupid=ledgrp.ledgergroupid
        and led.ledgerid=consledmap.ledgerid 
        and led.hospitalid = p_hospitalid and ledgrp.hospitalid=p_hospitalid;
END;
$$ LANGUAGE plpgsql;