CREATE OR REPLACE FUNCTION sp_bil_getitems_foripbillingdischargesummaryreceipt(
    p_patientid INT DEFAULT NULL,
    p_patientvisitid INT DEFAULT NULL,
    p_dischargestatementid INT DEFAULT NULL,
    p_billstatus VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
BEGIN
    /*
    filename: "sp_bil_getitems_foripbillingdischargesummaryreceipt" 
    createdby/date: rohit/1mar'23
    Description: To get the discharge summary details 
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Rohit/28Feb'23                        created the script
    2		rohit/24apr'23						  Query mistake resolved (mistake: DiscountAmount fetched in SubTotal)
    3		Krishna/27thApril'23				  change deposittype to transactiontype and segregate amount to inamount and outamount
    4.      bibek/27thjuly'23                     Added wardNumber and MunicipalityName columns in PatientInfo
    */
    BEGIN
    	OPEN ref1 FOR SELECT pat.PatientId
    		,pat.ShortName AS "ShortName"
    		,pat.PatientCode AS "PatientCode"
    		,pat.DateOfBirth
    		,pat.Gender, pat.WardNumber
    		,Address
    		,PhoneNumber
    		,patv.VisitCode
    		,subdiv.CountrySubDivisionName,
    		country.CountryName,
    		mun.MunicipalityName
    		,pat.PANNumber
    		,pat.Ins_NshiNumber
    		,patv.ClaimCode
    		,patv.VisitCode AS "InpatientNo"
    	FROM PAT_Patient pat
    	INNER JOIN PAT_PatientVisits patv ON pat.PatientId = patv.PatientId AND patv.PatientVisitId=p_patientvisitid
    	INNER JOIN ADT_PatientAdmission adm ON patv.PatientVisitId = adm.PatientVisitId
    		INNER JOIN MST_Country country ON pat.CountryId = country.CountryId
    	INNER JOIN MST_CountrySubDivision subdiv ON pat.CountrySubDivisionId = subdiv.CountrySubDivisionId
    	LEFT JOIN MST_Municipality mun ON subdiv.CountrySubDivisionId = mun.CountrySubDivisionId
    
    
    
    	WHERE pat.PatientId = p_patientid
    		AND patv.PatientVisitId = p_patientvisitid;
        RETURN NEXT ref1;
    
    	--Table:2--Bill Item Summary------------
    	IF p_dischargestatementid !=0
    	THEN
    		OPEN ref2 FOR SELECT ServiceDepartmentName
    			,SubTotal
    			,DiscountAmount
    			,TotalAmount
    		FROM (
    			SELECT a.ServiceDepartmentName
    				,SUM(SubTotal) AS "SubTotal"
    				,SUM(DiscountAmount) AS "DiscountAmount"
    				,SUM(TotalAmount) AS "TotalAmount"
    			FROM (
    				SELECT ServiceDepartmentName
    					,SubTotal
    					,DiscountAmount AS "DiscountAmount"
    					,TotalAmount
    				FROM BIL_TXN_BillingTransactionItems
    				WHERE (
    						(
    							BillStatus = p_billstatus
    							AND PatientId = p_patientid
    							AND PatientVisitId = p_patientvisitid
    							)
    						OR (
    							DischargeStatementId = p_dischargestatementid
    							AND PatientId = p_patientid
    							AND PatientVisitId = p_patientvisitid
    							)
    						)
    				) a
    			GROUP BY a.ServiceDepartmentName
    			
    			UNION
    			
    			SELECT ServiceDepartmentName
    				,SUM(SubTotal) AS "SubTotal"
    				,SUM(DiscountAmount) AS "DiscountAmount"
    				,SUM(TotalAmount)
    			FROM (
    				SELECT 'pharmacycharges' AS ServiceDepartmentName
    					,SubTotal
    					,TotalDisAmt AS "DiscountAmount"
    					,TotalAmount
    				FROM PHRM_TXN_InvoiceItems
    				WHERE DischargeStatementId = p_dischargestatementid
    					AND PatientId = p_patientid
    				) b
    			GROUP BY ServiceDepartmentName
    			) b;
        RETURN NEXT ref2;
    	
    	ELSE
    	
    		OPEN ref3 FOR SELECT ServiceDepartmentName
    			,SubTotal
    			,DiscountAmount
    			,TotalAmount
    		FROM (
    			SELECT a.ServiceDepartmentName
    				,SUM(SubTotal) AS "SubTotal"
    				,SUM(DiscountAmount) AS "DiscountAmount"
    				,SUM(TotalAmount) AS "TotalAmount"
    			FROM (
    				SELECT ServiceDepartmentName
    					,SubTotal
    					,DiscountAmount AS "DiscountAmount"
    					,TotalAmount
    				FROM BIL_TXN_BillingTransactionItems
    				WHERE (
    						(
    							BillStatus = p_billstatus
    							AND PatientId = p_patientid
    							AND PatientVisitId = p_patientvisitid
    							)
    						OR (
    							DischargeStatementId = p_dischargestatementid
    							AND PatientId = p_patientid
    							AND PatientVisitId = p_patientvisitid
    							)
    						)
    				) a
    			GROUP BY a.ServiceDepartmentName
    			
    			UNION
    			
    			SELECT ServiceDepartmentName
    				,SUM(SubTotal) AS "SubTotal"
    				,SUM(DiscountAmount) AS "DiscountAmount"
    				,SUM(TotalAmount)
    			FROM (
    				SELECT 'pharmacycharges' AS ServiceDepartmentName
    					,SubTotal
    					,TotalDisAmt AS "DiscountAmount"
    					,TotalAmount
    				FROM PHRM_TXN_InvoiceItems
    				WHERE BilItemStatus = p_billstatus AND PatientId = p_patientid
    				) b
    			GROUP BY ServiceDepartmentName
    			) b;
        RETURN NEXT ref3;
    	END IF;
    
    	--Table:3 --Admission Info----
    	OPEN ref4 FOR SELECT adm.AdmissionDate
    		,adm.DischargeDate
    		,DepartmentName AS "Department"
    		,ward.WardName AS "RoomType"
    		,patv.PerformerName AS "AdmittingDoctor"
    		,adm.ProcedureType
    		,DATEDIFF(day, adm.AdmissionDate, COALESCE(adm.DischargeDate, CURRENT_TIMESTAMP)) AS LengthOfStay
    	FROM PAT_PatientVisits patv
    	INNER JOIN ADT_PatientAdmission adm ON patv.PatientVisitId = adm.PatientVisitId
    	INNER JOIN MST_Department mstdep ON patv.DepartmentId = mstdep.DepartmentId
    	INNER JOIN ADT_TXN_PatientBedInfo admBedInfo ON adm.PatientVisitId = admBedInfo.PatientVisitId
    	INNER JOIN ADT_MST_Ward ward ON admBedInfo.WardId = ward.WardID
    	WHERE patv.PatientId = p_patientid
    		AND patv.PatientVisitId = p_patientvisitid;
        RETURN NEXT ref4;
    
    	--Table:4 --Deposit Info----
    	OPEN ref5 FOR SELECT dep.DepositId
    		,dep.IsActive
    		,ReceiptNo
    		,dep.CreatedOn AS "Date"
    		,dep.InAmount
    		,dep.OutAmount
    		,dep.DepositBalance AS "Balance"
    		,TransactionType
    		,CASE 
    			WHEN dep.SettlementId IS NOT NULL
    				THEN 'sr' || dep.receiptno
    			else null
    			end as referenceinvoice
    	from bil_txn_deposit dep
    	left join bil_txn_settlements sett on dep.settlementid = sett.settlementid
    	where dep.patientid = p_patientid
    		and dep.patientvisitid = p_patientvisitid
    	order by dep.createdon;
        return next ref5;
    
    	--table:5--dischargestatement details---
    	open ref6 for select dischargestatementid
    		,statementdate
    		,statementno
    		,statementtime
    	from bil_txn_dischargestatement
    	where dischargestatementid = p_dischargestatementid;
        return next ref6;
    end;
END;
$$ LANGUAGE plpgsql;