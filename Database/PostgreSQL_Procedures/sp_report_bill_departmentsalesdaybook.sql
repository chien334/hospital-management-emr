CREATE OR REPLACE FUNCTION sp_report_bill_departmentsalesdaybook(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_isinsurance BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    "FromDate" TIMESTAMP,
    "ToDate" TIMESTAMP,
    "ServDeptName" VARCHAR,
    "Quantity" INT,
    "Price" DECIMAL,
    "Tax" VARCHAR,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "ReturnAmount" DECIMAL,
    "ReturnTax" VARCHAR,
    "CancelAmount" DECIMAL,
    "CancelTax" VARCHAR,
    "NetSales" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_bill_departmentsalesdaybook"
    createdby/date: dinesh/2018-08-01
    description: to get the collection department wise 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       dinesh/2018-08-01					na										
    1       sud/06aug'29                 Added clause for Insurance
    
    */
    
    
    BEGIN
    If(p_fromdate IS NOT NULL OR p_todate IS NOT NULL)
    	THEN 
    			RETURN QUERY WITH DepartmentWiseSalesCTE as
      (
      
      select 
      --(Cast(ROW_NUMBER() OVER (ORDER BY  ServiceDepartmentName)   as int)) as SN,
      (vwTxnItm.BillingDate)::date AS "Date",
            sd.ServiceDepartmentName, itms.ItemName,
       CASE when (sd.ServiceDepartmentName='biochemistry' ) 
           OR(sd.ServiceDepartmentName='hematology' )
           OR(sd.ServiceDepartmentName='atomic absortion') 
           OR(sd.ServiceDepartmentName='clnical pathology' )
           OR(sd.ServiceDepartmentName='cytology'  )
           OR(sd.ServiceDepartmentName='kidney biopsy'  )
           OR(sd.ServiceDepartmentName='skin biopsy'  )
           OR(sd.ServiceDepartmentName='conjunctival biopsy' )
    	   OR(sd.ServiceDepartmentName='external lab-3' )
    	   OR(sd.ServiceDepartmentName='external lab - 1' )
    	   OR(sd.ServiceDepartmentName='external lab - 2'  )
    	   OR(sd.ServiceDepartmentName='histopathology'  )
    	   OR(sd.ServiceDepartmentName='immunohistrochemistry'  )
    	   OR(sd.ServiceDepartmentName='molecular diagnostics'  )
    	   OR(sd.ServiceDepartmentName='specialised biophysics assays'  )
    	   OR(sd.ServiceDepartmentName='serology'  )
    	   OR(sd.ServiceDepartmentName='laboratory'  )
    	   OR(sd.ServiceDepartmentName='microbiology'  )
    
    
    
        then 'labs'  
    	when (sd.ServiceDepartmentName='duct')
    OR(sd.ServiceDepartmentName='mammology')
    OR(sd.ServiceDepartmentName='performance test') 
    OR(sd.ServiceDepartmentName='mri')
    OR(sd.ServiceDepartmentName='c.t. scan')
    OR(sd.ServiceDepartmentName='ultrasound')
    OR(sd.ServiceDepartmentName='ultrasound color doppler')
    OR(sd.ServiceDepartmentName='bmd-bonedensitometry')
    OR(sd.ServiceDepartmentName='opg-orthopantogram')
    OR(sd.ServiceDepartmentName='mammography')
    OR(sd.ServiceDepartmentName='x-ray')
    OR(sd.ServiceDepartmentName='dexa')
    OR(sd.ServiceDepartmentName='imaging')
    then ('radiology')
    when(sd.ServiceDepartmentName='non invasive cardio vascular investigations')
    OR(sd.ServiceDepartmentName='cardiovascular surgery')
    then 'ctvs'
         ELSE sd.ServiceDepartmentName END AS "ServDeptName",
    	 COALESCE(vwTxnItm.PaidQuantity,0)+COALESCE(vwTxnItm.UnpaidQuantity,0) AS "Quantity" ,
         COALESCE(vwTxnItm.PaidSubTotal,0)+COALESCE(vwTxnItm.UnpaidSubTotal,0)  as SubTotal,
         COALESCE(vwTxnItm.PaidTax,0)+COALESCE(vwTxnItm.UnpaidTax,0) AS "Tax",
         COALESCE(vwTxnItm.PaidDiscountAmount,0)+COALESCE(vwTxnItm.UnpaidDiscountAmount,0) AS "DiscountAmount",
         COALESCE(vwTxnItm.PaidTotalAmount,0)+COALESCE(vwTxnItm.UnpaidTotalAmount,0) AS "TotalAmount",
    	
    	COALESCE(vwTxnItm.CancelSubTotal,0) as CancelSubTotal,
    	 COALESCE(vwTxnItm.CancelDiscountAmount,0) as CancelDiscountAmount,
    	  --COALESCE(cancelonsameday.CancelTotalAmountDay,0) as CancelTotalAmountDay,
    	  --  COALESCE(cancelonsameday.CancelDiscountAmountDay,0) as CancelDiscountDay,
    	 
       COALESCE(vwTxnItm.CancelTotalAmount,0) AS "CancelAmount",
       COALESCE(vwTxnItm.CancelTax,0) AS "CancelTax",
        ( case when BillStatus='return' then (COALESCE(vwTxnItm.ReturnTotalAmount,0)) 
    	 ELSE 0 END) AS "ReturnAmount",
         COALESCE(vwTxnItm.ReturnTax,0) AS "ReturnTax"
        from BIL_MST_ServiceDepartment sd, BIL_CFG_BillItemPrice itms, VW_BIL_TxnItemsInfo vwTxnItm 
    
    	  where   vwTxnItm.BillingDate between (p_fromdate)::date AND  (p_todate)::date 
           AND vwTxnItm.ServiceDepartmentId  = sd.ServiceDepartmentId
         AND vwTxnItm.ItemId=itms.ItemId
         AND sd.ServiceDepartmentId = itms.ServiceDepartmentId
    	 AND  COALESCE(vwTxnItm.IsInsurance,0)= p_isinsurance
    
          
    ) 
    Select 
    (p_fromdate)::date AS "FromDate",
         (p_todate)::date AS "ToDate",
         txnItms.ServDeptName AS "ServDeptName",
    	 sum(txnItms.Quantity) AS "Quantity",
         sum(txnItms.SubTotal) AS "Price",
         round(sum(txnItms.Tax),2) AS "Tax",
         sum(txnItms.DiscountAmount) AS "DiscountAmount",
         sum(txnItms.TotalAmount) AS "TotalAmount",
         sum(txnItms.ReturnAmount) AS "ReturnAmount",
         sum(txnItms.ReturnTax) AS "ReturnTax",
       Sum(txnItms.CancelAmount) AS "CancelAmount",
       Sum(txnItms.CancelTax) AS "CancelTax",
       Sum(txnItms.TotalAmount)-Sum(txnItms.Tax)-sum(txnItms.ReturnAmount) AS "NetSales"
      -- Sum(txnItms.CancelTotalAmountDay) 'canceltotalamountday',
      --Sum (txnItms.CancelDiscountDay) 'canceldiscountday'
    from departmentwisesalescte txnitms 
    group by txnitms.servdeptname;
    
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;