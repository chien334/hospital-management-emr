--Altering SP_Report_BIL_DoctorReport SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DoctorReport] --- [SP_Report_BIL_DoctorReport] '2018-08-08','2018-08-08'  
 @FromDate DateTime=null,  
 @ToDate DateTime=null,  
 @PerformerName varchar(max)=null  
AS  
/*  
FileName: [SP_Report_BIL_DoctorReport]  
CreatedBy/date: nagesh/2017-05-25  
Description: to get count of appointments per Department between given dates.  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1       nagesh/2017-05-25                      created the script  
2       umed / 2017-06-14                        Modify the script i.e format   
                                                 and remove time from paid date    
3.      dinesh/ 2017-08-04				Modified the script and maintained the Return as well as Cancel Status   
4       Umed/2018-04-17                         Added Order by Date in Desc Order  
5.  ramavtar/2018-05-31						correction in where condition   
										(providerName didnt had space in between First & Last name)  
6.  ramavtar/2018-08-17					changed the SP,now getting txn values from function 'FN_BIL_GetTxnItemsInfoWithDateSeparation' 
7.	Krishna/9thJun'22					changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
    IF (@FromDate IS NOT NULL)  
        OR (@ToDate IS NOT NULL)  
        OR (@PerformerName IS NOT NULL)  
        OR (LEN(@PerformerName) > 0)  
    BEGIN  
        SELECT  
            COALESCE(fnItm.ReturnDate, fnItm.CreditDate, fnItm.PaidDate, fnItm.CancelledDate, fnItm.ProvisionalDate) 'Date',  
            ISNULL(fnItm.PerformerName, 'NoDoctor') 'Doctor',  
            p.PatientCode 'HospitalNo',  
            p.FirstName + ISNULL(p.MiddleName + ' ', '') + p.LastName 'PatientName',  
            fnItm.ServiceDepartmentName 'Department',  
            fnItm.ItemName 'Item',  
            ISNULL(vmItm.Price, 0) 'Rate',  
            ISNULL(vmItm.Quantity, 0) 'Quantity',  
            fnItm.SubTotal 'SubTotal',  
            fnItm.DiscountAmount 'Discount',  
            fnItm.TotalAmount 'Total',  
            fnItm.ReturnAmount 'ReturnAmount',  
            fnItm.CancelledAmount 'CancelTotal',  
            ISNULL(fnItm.TotalAmount, 0) - ISNULL(fnItm.CancelledAmount, 0) - ISNULL(fnItm.ReturnAmount, 0) 'NetAmount'  
        FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(@FromDate, @ToDate) fnItm  
        JOIN VW_BIL_TxnItemsInfoWithDateSeparation vmItm  
            ON fnItm.BillingTransactionItemId = vmItm.BillingTransactionItemId  
        JOIN PAT_Patient p  
            ON fnItm.PatientId = p.PatientId  
        WHERE fnItm.PerformerName LIKE '%' + ISNULL(@PerformerName, '') + '%'  
        ORDER BY COALESCE(fnItm.ReturnDate, fnItm.CreditDate, fnItm.PaidDate, fnItm.CancelledDate, fnItm.ProvisionalDate) DESC  
    END  
END