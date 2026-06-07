/* =============================================
-- Author:		<Dev Narayan Chaudhary>
-- Create date: <2021 Nov 24>
-- Description:	Get Edit history of patients whose Name was edited 
-- Remarks: Currently we're tracking only Name change, we can extend this to track other changes of patient as well.
     

-- =============================================
Change History:
SN      User/Date                   Remarks
1.      DevNarayan/27Dec'2021       Initial Draft
2.      Rusha/24Feb'2022			Registered name and edited name is not showing of different user login after edited patient

*/
CREATE OR REPLACE FUNCTION sp_report_pat_editedpatientdetailreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_userid INT DEFAULT NULL
)
RETURNS TABLE (
    "Hospital Number" VARCHAR,
    "Patient Old Name" VARCHAR,
    "Patient New Name" VARCHAR,
    "Registered By" VARCHAR,
    "Edited By" VARCHAR,
    "Registered Date" TIMESTAMP,
    "Edited Date" TIMESTAMP
) AS $$
BEGIN
    
    RETURN QUERY SELECT
    	   data."hospital number",
    	   data."patient old name",
    	   data."patient new name",
    	   data."registered by",
    	   data."edited by",
    	   data."registered date",
    	   data."edited date"
            from (
              select 
    		  patient.patientcode AS "Hospital Number",
    		  history.patientoldname AS "Patient Old Name",
    		  history.patientnewname AS "Patient New Name",
    		  users.username AS "Registered By",
    		  modfier.username AS "Edited By",
    		  patient.createdon AS "Registered Date",
    		  history.createdon AS "Edited Date",
    		  history.createdby as updater,
    		  patient.createdby as creater
    		  from pat_history_patientname history
              join pat_patient patient on history.patientid = patient.patientid
    		     left join rbac_user users on patient.createdby= users.employeeid
    		     left join rbac_user modfier on  history.createdby = modfier.employeeid
    		  ) as data
    		  where 
    		    ( coalesce(p_userid,data.updater) =data.updater
    		     or   data.creater = p_userid or p_userid =0
    		     or coalesce(p_userid,data.creater) =data.creater )
    		  
    		  and ((data."registered date")::date between p_fromdate 
    		  and p_todate 
    		  or (data."edited date")::date between p_fromdate 
    		  and p_todate  or p_fromdate is null or p_todate is null)
    order by data."edited date" desc;
END;
$$ LANGUAGE plpgsql;