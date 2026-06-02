CREATE PROCEDURE [dbo].[SP_PHRM_UserwiseCollectionReport]

    @FromDate datetime=NULL,
    @ToDate datetime=NULL,
    @CounterId varchar(max)=NULL,
    @CreatedBy varchar(max)=NULL,
    @StoreId int = NULL
AS
 /*
 SP_PHRM_UserwiseCollectionReport '2020-04-01','2022-01-01','1','admin',22
FileName: [[SP_PHRM_UserwiseCollectionReport]]
CreatedBy/date: Nagesh/Vikas/2018-07-31
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nagesh/Vikas/2018-07-31                       created the script
2      Abhishek/2018-08-06           Return and NetAmount calculation
3     Salakha/2019-08-26          Billing type wise Calculation 
4.     Dinesh /Abhishek 2nd Sept 2019    Counter corrected for pharmacy 
5.      Shankar 23rd March 2020             Included deposit deduct and deposit refund
6.    Sanjit/Ramesh 12 April 2021      Added StoreId as parameter for filtering by dispensary
7.      Sanjit/16Jun2021                    Added StoreName to show in grid
8:      Ramesh/Rohit 12Dec'21               New Fxn added for Summary View, Case changed for Settlement Details ie Newly SP Changes for User Collection Report
9.    Rohit/14th Jan'22          passed new parameter 'CreatedBy' in FN_PHRM_GetUserCollectionSummaryInDateRange
10.    ROhit/31th May'22          Added Employee Cash Transaction Details.
*/
 BEGIN
    IF ((@FromDate IS NOT NULL) AND (@ToDate IS NOT NULL)) 
    BEGIN
        SELECT
            bills.Date,
            bills.InvoiceNo 'ReceiptNo',
            pat.PatientCode 'HospitalNo',
            pat.FirstName + ISNULL(' ' + pat.MiddleName, '') + ' ' + pat.LastName AS PatientName,
            bills.TransactionType 'TransactionType',
            bills.SubTotal,
            bills.DiscountAmount,
            bills.VATAmount,
            bills.TotalAmount,
            bills.CashCollection,
            bills.DepositReceived,
            bills.DepositRefund,
            bills.DepositDeduct,
            bills.CreditReceived,
            bills.CreditAmount,
            bills.CounterId,
            cntr.CounterName,
            bills.StoreId,
            str.Name 'StoreName',
            bills.[EmployeeId],
            bills.Remarks,
            emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName AS CreatedBy
        FROM ( 

                          SELECT *
                FROM FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDate,@ToDate,@StoreId)

            UNION ALL

                --All Deposits Transactions---
                SELECT CONVERT(Date,CreatedOn) 'Date',
                    'DR'+ CONVERT(varchar(20),ISNULL(ReceiptNo,'')) 'InvoiceNo',
                    Patientid,
                    0 AS 'InvoiceId',
                    CASE WHEN DepositType='deposit' THEN 'AdvanceReceived' 
                WHEN DepositType='depositdeduct' OR DepositType='depositreturn' THEN 'AdvanceSettled' END AS 'TransactionType',

                    0 AS SubTotal, 0 AS DiscountAmount, 0 AS VATAmount, 0 AS TotalAmount,
                    CASE WHEN DepositType='deposit' THEN DepositAmount WHEN DepositType='depositdeduct' OR DepositType='depositreturn' THEN (-DepositAmount) END AS 'CashCollection',
                    CASE WHEN DepositType='deposit' THEN DepositAmount ELSE 0 END AS 'DepositReceived',
                    CASE WHEN  DepositType='depositreturn' THEN DepositAmount ELSE 0 END AS 'DepositRefund',
					CASE WHEN  DepositType='depositdeduct' THEN DepositAmount ELSE 0 END AS 'DepositDeduct'
               , 0 AS CreditReceived, 0 AS 'CreditAmount',
                    CounterId 'CounterId', StoreId, CreatedBy 'EmployeeId', Remark 'Remarks', 6 AS DisplaySeq
                FROM PHRM_Deposit
                WHERE (StoreId = @StoreId OR @StoreId IS NULL) AND CONVERT(Date,CreatedOn) BETWEEN @FromDate AND @ToDate  


      ) bills,

            EMP_Employee emp,
            PAT_Patient pat,
            PHRM_MST_Counter cntr,
            PHRM_MST_Store str
        WHERE bills.PatientId = pat.PatientId
            AND emp.EmployeeId = bills.EmployeeId
            AND bills.CounterId = cntr.CounterId
            AND bills.StoreId = str.StoreId
            AND (bills.CounterId LIKE '%' + ISNULL(@CounterId, bills.CounterId) + '%')
            AND (emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName LIKE '%' + ISNULL(@CreatedBy, emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName) + '%')

        ORDER BY bills.DisplaySeq


        --Table2: For Settlement Details---
        --Need: CollectionFromReceivable,  CashDiscount and Return Cash Discount in given date range for given counter, user--
        --Getting Total(SUM) for all given criterias-- no need to separate for each user/counters/dates---
        SELECT
            --Case When sett.PayableAmount > 0 then PayableAmount - ( DepositDeducted + ISNULL(DiscountAmount,0) + ISNULL(DueAmount,0)) ELSE 0 END AS PaidAmount, 
            --SUM(Case When sett.PayableAmount > 0 then sett.PaidAmount ELSE 0 END) AS 'SettlPaidAmount', 
            --SUM( Case WHEN sett.RefundableAmount > 0 THEN sett.ReturnedAmount ELSE 0 END ) AS 'SettlReturnAmount',
            --SUM( Case WHEN sett.DueAmount > 0 THEN sett.DueAmount ELSE 0 END ) AS 'SettlDueAmount',
            --SUM( Case WHEN  sett.DiscountAmount > 0 THEN sett.DiscountAmount ELSE 0 END  ) 'SettlDiscountAmount'

            Sum(Isnull(sett.CollectionFromReceivable,0)) 'CollectionFromReceivables',
            Sum(Isnull(sett.DiscountAmount,0)) 'CashDiscountGiven',
            Sum(Isnull(sett.DiscountReturnAmount,0)) 'CashDiscountReceived'

        FROM PHRM_TXN_Settlement sett,
            EMP_Employee emp,
            PHRM_MST_Counter cntr,
      PHRM_MST_Store store


        WHERE sett.CreatedBy=emp.EmployeeId
            AND sett.CounterId=cntr.CounterId
      AND sett.StoreId = store.StoreId
            AND (sett.CounterId LIKE '%' + ISNULL(@CounterId, sett.CounterId) + '%')
            AND (emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName LIKE '%' + ISNULL(@CreatedBy, emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName) + '%')
            AND CONVERT(Date,sett.CreatedOn) BETWEEN CONVERT(Date, @FromDate) AND CONVERT(Date, @ToDate)
        --Group By sett.CreatedBy, sett.CounterId,emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName 

        --table:3--Gets User Collection Summary for all users in the given date range---
        SELECT *
        FROM FN_PHRM_GetUserCollectionSummaryInDateRange(@FromDate,@ToDate,@StoreId,@CreatedBy)

    --table:4--Get Pharmacy Employee Cash Transaction Details for all users in the given date range----------
    SELECT 
       pm.PaymentSubCategoryId
      ,pm.PaymentSubCategoryName
      ,SUM(empTxn.InAmount - empTxn.OutAmount) 'Collection'
    FROM PHRM_EmployeeCashTransaction empTxn
      INNER JOIN MST_PaymentModes pm ON empTxn.PaymentModeSubCategoryId = pm.PaymentSubCategoryId
    INNER JOIN EMP_Employee emp ON empTxn.EmployeeId=emp.EmployeeId
    WHERE 
     pm.PaymentSubCategoryName != 'Deposit'
    AND CONVERT(DATE,empTxn.TransactionDate) BETWEEN Convert(Date, @FromDate) AND Convert(Date, @ToDate)
    AND (emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName LIKE '%' + ISNULL(@CreatedBy, emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName) + '%')
    GROUP BY 
     pm.PaymentSubCategoryId,
     pm.PaymentSubCategoryName
	END
END