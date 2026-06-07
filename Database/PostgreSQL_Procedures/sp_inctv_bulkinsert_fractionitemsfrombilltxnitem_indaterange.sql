CREATE OR REPLACE FUNCTION sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_indaterange(
    p_fromdate VARCHAR DEFAULT NULL,
    p_todate VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
     file: sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_indaterange
    */
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
            ,"IsReturnTxn"
            ,"Quantity"
            )
        select
            fyear."FiscalYearFormatted" || '-' || txn."InvoiceCode" || cast(txn."InvoiceNo" as varchar(20)) as "invoicenoformatted"
            ,txn."CreatedOn" as "transactiondate"
            ,sett."PriceCategoryName" as "pricecategory"
            ,txn."BillingTransactionId"
            ,txnitm."BillingTransactionItemId"
            ,txn."PatientId"
            ,sett."ServiceItemId"
            ,sett."ItemName"
            ,txnitm."TotalAmount" as "totalbillamount"
            ,'prescriber' as incentivetype
            ,txnitm."PrescriberId" as "incentivereceiverid"
            ,sett."FullName" as "incentivereceivername"
            ,sett."PrescriberPercent" as "finalincentivepercent"
            ,(
                txnitm."TotalAmount" - (txnitm."TotalAmount" * coalesce((select  "ReferrerPercent" from "INCTV_MAP_EmployeeBillItemsMap" where "ServiceItemId" = sett."ServiceItemId" and "EmployeeId" = txnitm."ReferredById" limit 1), 0) / 100)) * coalesce(sett."PrescriberPercent", 0) / 100 as "incentiveamount"
            ,case 
                when txnitm."TotalAmount" <> 0
                    then (((txnitm."TotalAmount" -(txnitm."TotalAmount" * coalesce((
                                                select  "ReferrerPercent"
                                                from "INCTV_MAP_EmployeeBillItemsMap"
                                                where "ServiceItemId" = sett."ServiceItemId"
                                                and "EmployeeId" = txnitm."ReferredById" limit 1), 0) / 100)) * coalesce(sett."PrescriberPercent", 0) / 100) / txnitm."TotalAmount") * 100
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
            ,coalesce(sett."TDSPercent", 0) as tdspercentage
            ,(txnitm."TotalAmount" * coalesce(sett."PrescriberPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
            ,false as isreturntxn
            ,txnitm."Quantity"
        from "BIL_TXN_BillingTransaction" txn
        inner join "BIL_TXN_BillingTransactionItems" txnitm on txn."BillingTransactionId" = txnitm."BillingTransactionId"
        inner join "PAT_Patient" pat on txn."PatientId" = pat."PatientId"
        inner join "BIL_CFG_FiscalYears" fyear on txn."FiscalYearId" = fyear."FiscalYearId"
        inner join fn_inctv_getincentivesettings_normal() sett on txnitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
            and txnitm."ServiceItemId" = sett."ServiceItemId"
            and txnitm."PrescriberId" = sett."EmployeeId"
            and txnitm."PriceCategoryId" = sett."PriceCategoryId"
            and 1 = (
                case 
                    when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                        then 1
                    when sett."BillingTypesApplicable" = txnitm."BillingType"
                        then 1
                    else 0
                    end
                )
        where (txn."CreatedOn")::date between (p_fromdate)::date
                and (p_todate)::date
            and coalesce(sett."PrescriberPercent", 0) != 0
            and txnitm."BillingTransactionItemId" not in (
                select distinct "BillingTransactionItemId"
                from "INCTV_TXN_IncentiveFractionItem"
                where "IsReturnTxn" = false
                )
        
        union all
        
        select
            fyear."FiscalYearFormatted" || '-' || txn."InvoiceCode" || cast(txn."InvoiceNo" as varchar(20)) as "invoicenoformatted"
            ,txn."CreatedOn" as "transactiondate"
            ,sett."PriceCategoryName" as "pricecategory"
            ,txn."BillingTransactionId"
            ,txnitm."BillingTransactionItemId"
            ,txn."PatientId"
            ,sett."ServiceItemId"
            ,sett."ItemName"
            ,txnitm."TotalAmount" as "totalbillamount"
            ,'performer' as incentivetype
            ,txnitm."PerformerId" as "incentivereceiverid"
            ,sett."FullName" as "incentivereceivername"
            ,sett."PerformerPercent" as "finalincentivepercent"
            ,(
                txnitm."TotalAmount" - (txnitm."TotalAmount" * coalesce((
                            select  "ReferrerPercent"
                            from "INCTV_MAP_EmployeeBillItemsMap"
                            where "ServiceItemId" = sett."ServiceItemId"
                            and "EmployeeId" = txnitm."ReferredById" limit 1
                            ), 0) / 100
                    )
                ) * coalesce(sett."PerformerPercent", 0) / 100 as "incentiveamount"
            ,case 
                when txnitm."TotalAmount" <> 0
                    then (((txnitm."TotalAmount" - (txnitm."TotalAmount" * coalesce((select  "ReferrerPercent" from "INCTV_MAP_EmployeeBillItemsMap"
                                                 where "ServiceItemId" = sett."ServiceItemId" and "EmployeeId" = txnitm."ReferredById" limit 1 ), 0) / 100)) * coalesce(sett."PerformerPercent", 0) / 100) / txnitm."TotalAmount") * 100
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
            ,(txnitm."TotalAmount" * coalesce(sett."PerformerPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
            ,false as isreturntxn
            ,txnitm."Quantity"
        from "BIL_TXN_BillingTransaction" txn
        inner join "BIL_TXN_BillingTransactionItems" txnitm on txn."BillingTransactionId" = txnitm."BillingTransactionId"
        inner join "PAT_Patient" pat on txn."PatientId" = pat."PatientId"
        inner join "BIL_CFG_FiscalYears" fyear on txn."FiscalYearId" = fyear."FiscalYearId"
        inner join fn_inctv_getincentivesettings_normal() sett on txnitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
            and txnitm."ServiceItemId" = sett."ServiceItemId"
            and txnitm."PerformerId" = sett."EmployeeId"
            and txnitm."PriceCategoryId" = sett."PriceCategoryId"
            and 1 = (
                case 
                    when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                        then 1
                    when sett."BillingTypesApplicable" = txnitm."BillingType"
                        then 1
                    else 0
                    end
                )
        where (txn."CreatedOn")::date between (p_fromdate)::date
                and (p_todate)::date
            and coalesce(sett."PerformerPercent", 0) != 0
            and txnitm."BillingTransactionItemId" not in (
                select distinct "BillingTransactionItemId"
                from "INCTV_TXN_IncentiveFractionItem"
                where "IsReturnTxn" = false
                )
        
        union all
        
        select
            fyear."FiscalYearFormatted" || '-' || txn."InvoiceCode" || cast(txn."InvoiceNo" as varchar(20)) as "invoicenoformatted"
            ,txn."CreatedOn" as "transactiondate"
            ,sett."PriceCategoryName" as "pricecategory"
            ,txn."BillingTransactionId"
            ,txnitm."BillingTransactionItemId"
            ,txn."PatientId"
            ,sett."ServiceItemId"
            ,sett."ItemName"
            ,txnitm."TotalAmount" as "totalbillamount"
            ,'referral' as incentivetype
            ,txnitm."ReferredById" as "incentivereceiverid"
            ,sett."FullName" as "incentivereceivername"
            ,sett."ReferrerPercent" as "finalincentivepercent"
            ,txnitm."TotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100 as "incentiveamount"
            ,case 
                when txnitm."TotalAmount" <> 0
                    then ((txnitm."TotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100) / txnitm."TotalAmount") * 100
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
            ,(txnitm."TotalAmount" * coalesce(sett."ReferrerPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
            ,false as isreturntxn
            ,txnitm."Quantity"
        from "BIL_TXN_BillingTransaction" txn
        inner join "BIL_TXN_BillingTransactionItems" txnitm on txn."BillingTransactionId" = txnitm."BillingTransactionId"
        inner join "PAT_Patient" pat on txn."PatientId" = pat."PatientId"
        inner join "BIL_CFG_FiscalYears" fyear on txn."FiscalYearId" = fyear."FiscalYearId"
        inner join fn_inctv_getincentivesettings_normal() sett on txnitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
            and txnitm."ServiceItemId" = sett."ServiceItemId"
            and txnitm."ReferredById" = sett."EmployeeId"
            and txnitm."PriceCategoryId" = sett."PriceCategoryId"
            and 1 = (
                case 
                    when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                        then 1
                    when sett."BillingTypesApplicable" = txnitm."BillingType"
                        then 1
                    else 0
                    end
                )
        where (txn."CreatedOn")::date between (p_fromdate)::date
                and (p_todate)::date
            and coalesce(sett."ReferrerPercent", 0) != 0
            and txnitm."BillingTransactionItemId" not in (
                select distinct "BillingTransactionItemId"
                from "INCTV_TXN_IncentiveFractionItem"
                where "IsReturnTxn" = false
                )
        
        union all
        
        select
            fyear."FiscalYearFormatted" || '-' || txn."InvoiceCode" || cast(txn."InvoiceNo" as varchar(20)) as "invoicenoformatted"
            ,txn."CreatedOn" as "transactiondate"
            ,sett."PriceCategoryName" as "pricecategory"
            ,txn."BillingTransactionId"
            ,txnitm."BillingTransactionItemId"
            ,txn."PatientId"
            ,sett."ServiceItemId"
            ,sett."ItemName"
            ,txnitm."TotalAmount" as "totalbillamount"
            ,'performer' as incentivetype
            ,sett."ToEmployeeId" as "incentivereceiverid"
            ,sett."ToEmployeeName" as "incentivereceivername"
            ,sett."DistributionPercent" as "finalincentivepercent"
            ,txnitm."TotalAmount" * coalesce(sett."DistributionPercent", 0) / 100 as "incentiveamount"
            ,case 
                when txnitm."TotalAmount" <> 0
                    then ((txnitm."TotalAmount" * coalesce(sett."DistributionPercent", 0) / 100) / txnitm."TotalAmount") * 100
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
            ,(txnitm."TotalAmount" * coalesce(sett."DistributionPercent", 0) / 100) * coalesce(sett."TDSPercent", 0) / 100 as "tdsamount"
            ,false as isreturntxn
            ,txnitm."Quantity"
        from "BIL_TXN_BillingTransaction" txn
        inner join "BIL_TXN_BillingTransactionItems" txnitm on txn."BillingTransactionId" = txnitm."BillingTransactionId"
        inner join "PAT_Patient" pat on txn."PatientId" = pat."PatientId"
        inner join "BIL_CFG_FiscalYears" fyear on txn."FiscalYearId" = fyear."FiscalYearId"
        inner join fn_inctv_getincentivesettings_groupdistribution() sett
            on txnitm."ServiceDepartmentId" = sett."ServiceDepartmentId"
            and txnitm."ServiceItemId" = sett."ServiceItemId"
            and txnitm."PerformerId" = sett."FromEmployeeId"
            and txnitm."PriceCategoryId" = sett."PriceCategoryId"
            and 1 = (
                case 
                    when coalesce(sett."BillingTypesApplicable", 'both') = 'both'
                        then 1
                    when sett."BillingTypesApplicable" = txnitm."BillingType"
                        then 1
                    else 0
                    end
                )
        where (txn."CreatedOn")::date between (p_fromdate)::date
                and (p_todate)::date
            and coalesce(sett."DistributionPercent", 0) != 0
            and txnitm."BillingTransactionItemId" not in (
                select distinct "BillingTransactionItemId"
                from "INCTV_TXN_IncentiveFractionItem"
                where "IsReturnTxn" = false
                );
    end if;

    OPEN ref1 FOR SELECT 'success' as "status";
    return next ref1;
END;
$$ LANGUAGE plpgsql;