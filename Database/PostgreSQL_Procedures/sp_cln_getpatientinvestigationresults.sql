CREATE OR REPLACE FUNCTION sp_cln_getpatientinvestigationresults(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_patientid INT DEFAULT NULL,
    p_patientvisitid INT DEFAULT NULL
)
RETURNS TABLE (
    "Test" VARCHAR,
    "ComponentName" TIMESTAMP,
    "Unit" VARCHAR,
    "Value" DECIMAL,
    "ResultDate" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: "sp_patvisit_getpatientinvestigationresults"
    createdby/date: santosh/01aug'23
    Description: To get Patient's investigation results of current visit
    remarks:  
    note:  
    change history
    s.no.    updatedby/date                        remarks
    1        santosh/301aug'23					   Created
    */
    
    
        RETURN QUERY SELECT test.LabTestName AS "Test", comp.ComponentName, comp.Unit, result.Value , (result.CreatedOn)::DATE AS "ResultDate"
        FROM LAB_LabTests test
        INNER JOIN LAB_TXN_TestComponentResult result ON test.LabTestId = result.LabTestId
    	INNER JOIN LAB_TestRequisition labReq ON result.RequisitionId = labReq.RequisitionId
    	INNER JOIN Lab_MST_Components comp ON result.ComponentId= comp.ComponentId
    	WHERE (result.CreatedOn)::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE AND  labReq.PatientId = p_patientid AND labReq.PatientVisitId = p_patientvisitid 
    	AND comp.ControlType <> 'label'
        GROUP BY test.LabTestName,comp.ComponentName,comp.Unit, result.VALUE, (result.CreatedOn)::DATE
    
        UNION ALL
    
    	SELECT imgrep.ImagingTypeName AS "Test", '' AS "ComponentName", '' AS "Unit",'yes' AS "Value", (CreatedOn)::DATE AS "ResultDate"
        FROM RAD_PatientImagingReport imgrep  Where imgrep.OrderStatus = 'final' AND
    	(imgrep.CreatedOn)::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE AND  PatientId = p_patientid AND PatientVisitId = p_patientvisitid 
    	GROUP BY imgrep.ImagingTypeName,imgrep.OrderStatus, (CreatedOn)::DATE
    	
        UNION ALL
    
        SELECT 'input' AS "Test", '' AS "ComponentName", Unit, CAST(SUM(TotalIntake) AS VARCHAR(50)) AS "Value", (CreatedOn)::DATE AS "ResultDate"
        FROM CLN_InputOutput cln
    	INNER JOIN (SELECT  PatientId,PatientVisitId FROM PAT_PatientVisits WHERE  PatientId = p_patientid AND PatientVisitId =p_patientvisitid LIMIT 1 ) v ON cln.PatientVisitId = v.PatientVisitId
        WHERE IntakeType IS NOT NULL AND (cln.CreatedOn)::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::date AND  PatientId = p_patientid AND cln.PatientVisitId = p_patientvisitid 
        GROUP BY  Unit, (CreatedOn)::DATE 
    
        UNION ALL
    
        SELECT 'output' AS "Test",'' AS "ComponentName", unit, cast(sum(totaloutput) as varchar(50)) AS "Value", (createdon)::date AS "ResultDate"
        from cln_inputoutput cln
    	inner join (select  patientid,patientvisitid from pat_patientvisits where patientid = p_patientid and patientvisitid =p_patientvisitid limit 1 ) v on cln.patientvisitid = v.patientvisitid
        where outputtype is not null and (cln.createdon)::date between (p_fromdate)::date and (p_todate)::date and  patientid = p_patientid and cln.patientvisitid = p_patientvisitid 
        group by unit, (createdon)::date;
END;
$$ LANGUAGE plpgsql;