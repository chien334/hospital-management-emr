CREATE OR REPLACE FUNCTION sp_report_bil_referralsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_isexternal BOOLEAN DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*  
    change history  
    s.no.    updatedby/date     remarks  
    1.  sud/pratik/13oct'19        Initial Draft  
    2.      Dev/24th_Jan'22         change nodoctor to unassgined in case no doctor is selected  
    3.	krishna/9thjun'22		changed ReferredBy to PrescriberId and ReferrerName to PresriberName
    4.	Krishna/14thNov'22		  referreddoctorname changed to doctor
    */  
    begin  
        
      
    open ref1 for select  
            coalesce(prescriberid, 0) as "prescriberid",  
            case when coalesce(prescriberid, 0) != 0 then doctor else 'Unassigned' end as "prescribername",  
      --isextreferrer,  
      coalesce(emp.isexternal,0) as "isextreferrer",  
            sum(coalesce(subtotal, 0)) as "subtotal",  
            sum(coalesce(discountamount, 0)) as "discount",  
            sum(coalesce(returntotalamount, 0)) as "refund",  
            sum(coalesce(totalamount, 0) - coalesce(returntotalamount, 0)) as "nettotal",  
      
       sum(coalesce(creditamount, 0)) as "creditamount",  
       sum(coalesce(creditreceived, 0)) as "creditreceivedamount"  
      
        from fn_bill_get_billingtxnitemseggregation_bybillingtype_noprovisional(p_fromdate, p_todate) itm  
     left join emp_employee emp  
     on itm.prescriberid = emp.employeeid  
      
     where coalesce(emp.isexternal,0) = coalesce(p_isexternal, coalesce(emp.isexternal,0))  --take all records if inputparameter is null.  
      
     group by   
      prescriberid,  
      doctor,  
      coalesce(emp.isexternal,0)   
     order by 2;
        return next ref1;  
      
      
     open ref2 for select   
      sum(case when billstatus='provisional' then provisionalamount else 0 end) as "provisionalamount",  
      sum(case when billstatus='cancelled' then cancelledamount else 0 end) as "cancelledamount",  
      sum(case when billstatus='credit' then creditamount else 0 end) as "creditamount",  
      --sud:7feb'18--Added CreditReceivedAmount with below condition--  
      SUM(CASE WHEN BillStatus='paid' AND PaymentMode='credit' AND PaidDate is not null and CreditDate is null THEN PaidAmount ELSE 0 END) AS "CreditReceivedAmount",  
      --sud:7Feb'18: added creditreturnamount <needs revision>  
      sum(case when billstatus='return' and paymentmode='credit' and paiddate is null then returnamount else 0 end) as "creditreturnamount",  
      (select sum(coalesce(advancereceived,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancereceived",  
      (select sum(coalesce(advancesettled,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancesettled"  
    from fn_bil_gettxnitemsinfowithdateseparation_doctorsummary(p_fromdate, p_todate);
        return next ref2;  
    end;
END;
$$ LANGUAGE plpgsql;