CREATE OR REPLACE FUNCTION sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_return_indaterange(
    p_fromdate VARCHAR DEFAULT NULL,
    p_todate VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*  
     file: sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_return_indaterange
    */
    begin
        if (p_fromdate is not null and p_todate is not null)
        then
            insert into "INCTV_TXN_IncentiveFractionItem" (
                "InvoiceNoFormatted"
                ,"TransactionDate"
                ,"PriceCategory"
                ,"BillingTransactionId"
                ,"BillingTransactionItemId"
                ,"PatientId"
                ,"ServiceItemId"
                ,"ItemName"
                ,"TotalBillAmount"
                ,"IncentiveType"
                ,"IncentiveReceiverId"
                ,"IncentiveReceiverName"
                ,"FinalIncentivePercent"
                ,"IncentiveAmount"
                ,"InitialIncentivePercent"
                ,"IsPaymentProcessed"
                ,"PaymentInfoId"
                ,"CreatedBy"
                ,"CreatedOn"
                ,"ModifiedBy"
                ,"ModifiedOn"
                ,"IsActive"
                ,"IsMainDoctor"
                ,"TDSPercentage"
                ,"TDSAmount"
                ,"Quantity"
                ,"IsReturnTxn"
                ,"BillReturnItemId"
                )
            --section: 1-- start: for referral incentive (group distribnution not required for referral)----------
            select
                fyear."FiscalYearFormatted" || '-' || rettxn."InvoiceCode" || cast(rettxn."RefInvoiceNum" as varchar(20)) as "invoicenoformatted"
                ,rettxn."CreatedOn" as "transactiondate"
                ,sett."PriceCategoryName" as "pricecategory"
                ,rettxn."BillingTransactionId"
                ,retitm."BillingTransactionItemId"
                ,rettxn."PatientId"
                ,sett."ServiceItemId"
                ,sett."ItemName"
                ,- retitm."RetTotalAmount" as "totalbillamount"
                ,'prescriber' as incentivetype
                ,retitm."PrescriberId" as "incentivereceiverid"
                ,sett."FullName" as "incentivereceivername"
                ,sett."PrescriberPercent" as "incentivepercent"
                ,- (
                    retitm."RetTotalAmount" - (
                        retitm."RetTotalAmount" * coalesce((
                                select  "ReferrerPercent"
                                from "INCTV_MAP_EmployeeBillItemsMap"
                                where "ServiceItemId" = sett."ServiceItemId"
                                    and "EmployeeId" = txnitem."ReferredById" limit 1
                                ), 0) / 100
                        )
                    ) * coalesce(sett."PrescriberPercent", 0) / 100 as "incentiveamount"
                ,case 
                    when retitm."RetTotalAmount" <> 0
                        then (((retitm."RetTotalAmount" - (retitm."RetTotalAmount" * coalesce((select  "ReferrerPercent" from "INCTV_MAP_EmployeeBillItemsMap" where "ServiceItemId" = sett."ServiceItemId" and "EmployeeId" = txnitem."ReferredById" limit 1), 0) / 100)) * coalesce(sett."PrescriberPercent", 0) / 100) / retitm."RetTotalAmount") * 100
                    else 0
                    end as "initialincentivepercent"
                ,false as ispaymentprocessed
                ,null::integer as paymentinfoid
                ,1 as createdby
                ,current_timestamp as createdon
                ,null::integer as modifiedby
                ,null::timestamp as modifiedon
                ,true as isactive
                ,false as ismaindoctor
                ,coalesce(sett."TDSPercent", 0) as tdspercent
                ,- (retitm."RetTotalAmount" * coalesce(sett."PrescriberPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
                ,retitm."RetQuantity"
                ,true as isreturntxn
                ,retitm."BillReturnItemId"
            from "BIL_TXN_InvoiceReturn" rettxn
            inner join "BIL_TXN_InvoiceReturnItems" retitm
                on rettxn."BillReturnId" = retitm."BillReturnId"
            inner join "BIL_TXN_BillingTransactionItems" txnitem on retitm."BillingTransactionItemId" = txnitem."BillingTransactionItemId"
            inner join "PAT_Patient" pat on rettxn."PatientId" = pat."PatientId"
            inner join "BIL_CFG_FiscalYears" fyear on rettxn."FiscalYearId" = fyear."FiscalYearId"
            inner join fn_inctv_getincentivesettings_normal() sett on retitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
                and retitm."ServiceItemId" = sett."ServiceItemId"
                and retitm."PrescriberId" = sett."EmployeeId"
                and retitm."PriceCategoryId" = sett."PriceCategoryId"
                and 1 = (
                    case 
                        when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                            then 1
                        when sett."BillingTypesApplicable" = retitm."BillingType"
                            then 1
                        else 0
                        end
                    )
            where (rettxn."CreatedOn")::date between (p_fromdate)::date
                    and (p_todate)::date
                and coalesce(sett."PrescriberPercent", 0) != 0
                and retitm."BillReturnItemId" not in (
                    select distinct "BillReturnItemId"
                    from "INCTV_TXN_IncentiveFractionItem"
                    where "BillReturnItemId" is not null
                        and "IsReturnTxn" = true
                    )
            --section: 1-- end: for referral incentive (group distribnution not required for referral)----------
            
            union all
            
            select
                fyear."FiscalYearFormatted" || '-' || rettxn."InvoiceCode" || cast(rettxn."RefInvoiceNum" as varchar(20)) as "invoicenoformatted"
                ,rettxn."CreatedOn" as "transactiondate"
                ,sett."PriceCategoryName" as "pricecategory"
                ,rettxn."BillingTransactionId"
                ,retitm."BillingTransactionItemId"
                ,rettxn."PatientId"
                ,sett."ServiceItemId"
                ,sett."ItemName"
                ,- retitm."RetTotalAmount" as "totalbillamount"
                ,'performer' as incentivetype
                ,retitm."PerformerId" as "incentivereceiverid"
                ,sett."FullName" as "incentivereceivername"
                ,sett."PerformerPercent" as "incentivepercent"
                ,-(retitm."RetTotalAmount" -(retitm."RetTotalAmount" * coalesce((select  "ReferrerPercent" from "INCTV_MAP_EmployeeBillItemsMap" 
                                          where "ServiceItemId" = sett."ServiceItemId" and "EmployeeId" = txnitem."ReferredById" limit 1), 0) / 100)) * coalesce(sett."PerformerPercent",0) /100 as "incentiveamount"
                ,case 
                    when retitm."RetTotalAmount" <> 0
                        then (((retitm."RetTotalAmount" -(retitm."RetTotalAmount" * coalesce((select  "ReferrerPercent" from "INCTV_MAP_EmployeeBillItemsMap"
                                                       where "ServiceItemId" = sett."ServiceItemId" and "EmployeeId" = txnitem."ReferredById" limit 1), 0) / 100)) * coalesce(sett."PerformerPercent", 0) / 100) / retitm."RetTotalAmount") * 100
                    else 0
                    end as "initialincentivepercent"
                ,false as ispaymentprocessed
                ,null::integer as paymentinfoid
                ,1 as createdby
                ,current_timestamp as createdon
                ,null::integer as modifiedby
                ,null::timestamp as modifiedon
                ,true as isactive
                ,true as ismaindoctor
                ,coalesce(sett."TDSPercent", 0) as tdspercentage
                ,- (retitm."RetTotalAmount" * coalesce(sett."PerformerPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
                ,retitm."RetQuantity"
                ,true as isreturntxn
                ,retitm."BillReturnItemId"
            from "BIL_TXN_InvoiceReturn" rettxn
            inner join "BIL_TXN_InvoiceReturnItems" retitm on rettxn."BillReturnId" = retitm."BillReturnId"
            inner join "BIL_TXN_BillingTransactionItems" txnitem on retitm."BillingTransactionItemId" = txnitem."BillingTransactionItemId"
            inner join "PAT_Patient" pat on rettxn."PatientId" = pat."PatientId"
            inner join "BIL_CFG_FiscalYears" fyear on rettxn."FiscalYearId" = fyear."FiscalYearId"
            inner join fn_inctv_getincentivesettings_normal() sett on retitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
                and retitm."ServiceItemId" = sett."ServiceItemId"
                and retitm."PerformerId" = sett."EmployeeId"
                and retitm."PriceCategoryId" = sett."PriceCategoryId"
                and 1 = (
                    case 
                        when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                            then 1
                        when sett."BillingTypesApplicable" = retitm."BillingType"
                            then 1
                        else 0
                        end
                    )
            where (rettxn."CreatedOn")::date between (p_fromdate)::date
                    and (p_todate)::date
                and coalesce(sett."PerformerPercent", 0) != 0
                and retitm."BillReturnItemId" not in (
                    select distinct "BillReturnItemId"
                    from "INCTV_TXN_IncentiveFractionItem"
                    where "BillReturnItemId" is not null
                        and "IsReturnTxn" = true
                    )
            
            union all
            
            --section: 3-- start: for referral incentive----------
            select
                fyear."FiscalYearFormatted" || '-' || rettxn."InvoiceCode" || cast(rettxn."RefInvoiceNum" as varchar(20)) as "invoicenoformatted"
                ,rettxn."CreatedOn" as "transactiondate"
                ,sett."PriceCategoryName" as "pricecategory"
                ,rettxn."BillingTransactionId"
                ,retitm."BillingTransactionItemId"
                ,rettxn."PatientId"
                ,sett."ServiceItemId"
                ,sett."ItemName"
                ,- retitm."RetTotalAmount" as "totalbillamount"
                ,'referral' as incentivetype
                ,txnitem."ReferredById" as "incentivereceiverid"
                ,sett."FullName" as "incentivereceivername"
                ,sett."ReferrerPercent" as "incentivepercent"
                ,- (retitm."RetTotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100) as "incentiveamount"
                ,case 
                    when retitm."RetTotalAmount" <> 0
                        then (((retitm."RetTotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100) / retitm."RetTotalAmount") * 100)
                    else 0
                    end as "initialincentivepercent"
                ,false as ispaymentprocessed
                ,null::integer as paymentinfoid
                ,1 as createdby
                ,current_timestamp as createdon
                ,null::integer as modifiedby
                ,null::timestamp as modifiedon
                ,true as isactive
                ,false as ismaindoctor
                ,coalesce(sett."TDSPercent", 0) as tdspercent
                ,- (retitm."RetTotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
                ,retitm."RetQuantity"
                ,true as isreturntxn
                ,retitm."BillReturnItemId"
            from "BIL_TXN_InvoiceReturn" rettxn
            inner join "BIL_TXN_InvoiceReturnItems" retitm
                on rettxn."BillReturnId" = retitm."BillReturnId"
            inner join "BIL_TXN_BillingTransactionItems" txnitem on retitm."BillingTransactionItemId" = txnitem."BillingTransactionItemId"
            inner join "PAT_Patient" pat on rettxn."PatientId" = pat."PatientId"
            inner join "BIL_CFG_FiscalYears" fyear on rettxn."FiscalYearId" = fyear."FiscalYearId"
            inner join fn_inctv_getincentivesettings_normal() sett on retitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
                and retitm."ServiceItemId" = sett."ServiceItemId"
                and txnitem."ReferredById" = sett."EmployeeId"
                and retitm."PriceCategoryId" = sett."PriceCategoryId"
                and 1 = (
                    case 
                        when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                            then 1
                        when sett."BillingTypesApplicable" = retitm."BillingType"
                            then 1
                        else 0
                        end
                    )
            where (rettxn."CreatedOn")::date between (p_fromdate)::date
                    and (p_todate)::date
                and coalesce(sett."ReferrerPercent", 0) != 0
                and retitm."BillReturnItemId" not in (
                    select distinct "BillReturnItemId"
                    from "INCTV_TXN_IncentiveFractionItem"
                    where "BillReturnItemId" is not null
                        and "IsReturnTxn" = true
                    )
            --section: 1-- end: for referral incentive (group distribnution not required for referral)----------
            
            union all
            
            select
                fyear."FiscalYearFormatted" || '-' || rettxn."InvoiceCode" || cast(rettxn."RefInvoiceNum" as varchar(20)) as "invoicenoformatted"
                ,rettxn."CreatedOn" as "transactiondate"
                ,sett."PriceCategoryName" as "pricecategory"
                ,rettxn."BillingTransactionId"
                ,retitm."BillingTransactionItemId"
                ,rettxn."PatientId"
                ,sett."ServiceItemId"
                ,sett."ItemName"
                ,- retitm."RetTotalAmount" as "totalbillamount"
                ,'performer' as incentivetype
                ,sett."ToEmployeeId" as "incentivereceiverid"
                ,sett."ToEmployeeName" as "incentivereceivername"
                ,sett."DistributionPercent" as "incentivepercent"
                ,- retitm."RetTotalAmount" * coalesce(sett."DistributionPercent", 0) / 100 as "incentiveamount"
                ,((retitm."RetTotalAmount" * coalesce(sett."DistributionPercent", 0) / 100) / retitm."RetTotalAmount") * 100 as "initialincentivepercent"
                ,false as ispaymentprocessed
                ,null::integer as paymentinfoid
                ,1 as createdby
                ,current_timestamp as createdon
                ,null::integer as modifiedby
                ,null::timestamp as modifiedon
                ,true as isactive
                ,true as ismaindoctor
                ,coalesce(sett."TDSPercent", 0) as tdspercentage
                ,- (retitm."RetTotalAmount" * coalesce(sett."DistributionPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
                ,retitm."RetQuantity"
                ,true as isreturntxn
                ,retitm."BillReturnItemId"
            from "BIL_TXN_InvoiceReturn" rettxn
            inner join "BIL_TXN_InvoiceReturnItems" retitm on rettxn."BillReturnId" = retitm."BillReturnId"
            inner join "PAT_Patient" pat on rettxn."PatientId" = pat."PatientId"
            inner join "BIL_CFG_FiscalYears" fyear on rettxn."FiscalYearId" = fyear."FiscalYearId"
            inner join fn_inctv_getincentivesettings_groupdistribution() sett
                on retitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
                and retitm."ServiceItemId" = sett."ServiceItemId"
                and retitm."PerformerId" = sett."FromEmployeeId"
                and retitm."PriceCategoryId" = sett."PriceCategoryId"
                and 1 = (
                    case 
                        when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                            then 1
                        when sett."BillingTypesApplicable" = retitm."BillingType"
                            then 1
                        else 0
                        end
                    )
            where (rettxn."CreatedOn")::date between (p_fromdate)::date
                    and (p_todate)::date
                and coalesce(sett."DistributionPercent", 0) != 0
                and retitm."BillReturnItemId" not in (
                    select distinct "BillReturnItemId"
                    from "INCTV_TXN_IncentiveFractionItem"
                    where "BillReturnItemId" is not null
                        and "IsReturnTxn" = true
                    );
        end if;
    end;

    open ref1 for select 'success' as "status";
    return next ref1;
END;
$$ LANGUAGE plpgsql;