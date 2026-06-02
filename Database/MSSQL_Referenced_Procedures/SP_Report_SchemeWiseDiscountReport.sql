CREATE PROCEDURE [dbo].[SP_Report_SchemeWiseDiscountReport]
	--[SP_Report_SchemeWiseDiscountReport] '2023-07-28','2023-08-28',null
	@FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@SchemeId INT = NULL
AS
/*
  FileName: [SP_Report_SchemeWiseDiscountReport]
  CreatedBy/date: Pratik/2021-09-21
  Description: to get the Scheme Wise Discount Report for the hospital
  Remarks:    
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1       Pratik/2021-09-21				Created the Script
  2       Krishna/2022-04-08			Updated script by adding where condtion on membership id to filter out data
  3		  Sanjeev/2023-08-28			According to new structure, discard PAT_CFG_MembershipType table.
										Instead Use BIL_CFG_Scheme table.
										Replace MembershipTypeId with SchemeId, MemebershipTypeName with SchemeName, CommunityName with SchemeCode.
  */
BEGIN
	IF (@SchemeId = 0)
	BEGIN
		SET @SchemeId = NULL
	END

	SELECT *
	FROM (
		SELECT scheme.SchemeId
			,scheme.SchemeName
			,scheme.SchemeCode
			,cashtotalamount 'CashAmount'
			,credittotalamount 'CreditAmount'
			,ISNULL(sales.totalamount, 0) AS 'Total'
			,
			--ISNULL(sales.Subtotal,0) AS SalesSubtotal, 
			ISNULL(sales.discountamount, 0) AS 'Free_Cons_Amount'
			,ISNULL(ret.rettotalamount, 0) AS 'NetRefundAmount'
			,ISNULL(ret.retdiscountamount, 0) AS 'DiscountRefund'
			,ISNULL(sales.totalamount, 0) - ISNULL(ret.rettotalamount, 0) 'NetAmount'
		FROM BIL_CFG_Scheme scheme
		LEFT JOIN (
			SELECT itm.discountschemeid
				,SUM(itm.subtotal) 'Subtotal'
				,SUM(ISNULL(itm.discountamount, 0)) 'DiscountAmount'
				,SUM(itm.totalamount) 'TotalAmount'
				,SUM((
						CASE 
							WHEN txn.paymentmode = 'cash'
								THEN itm.totalamount
							ELSE 0
							END
						)) AS CashTotalAmount
				,SUM((
						CASE 
							WHEN txn.paymentmode = 'credit'
								THEN itm.totalamount
							ELSE 0
							END
						)) AS CreditTotalAmount
			FROM bil_txn_billingtransaction txn
			INNER JOIN bil_txn_billingtransactionitems itm ON txn.billingtransactionid = itm.billingtransactionid
			WHERE CONVERT(DATE, txn.createdon) BETWEEN @FromDate
					AND @ToDate
			GROUP BY itm.discountschemeid
			) sales ON scheme.SchemeId = sales.DiscountSchemeId
		LEFT JOIN (
			SELECT retItm.discountschemeid
				,Sum(retItm.retsubtotal) 'RetSubtotal'
				,SUM(ISNULL(retItm.retdiscountamount, 0)) 'RetDiscountAmount'
				,SUM(retItm.rettotalamount) 'RetTotalAmount'
			FROM bil_txn_invoicereturnitems retItm
			WHERE CONVERT(DATE, retItm.createdon) BETWEEN @FromDate
					AND @ToDate
			GROUP BY retItm.discountschemeid
			) ret ON scheme.SchemeId = ret.discountschemeid
		) tbl
	WHERE (
			--ISNULL(SalesSubtotal,0) !=0
			ISNULL(cashamount, 0) != 0
			OR ISNULL(creditamount, 0) != 0
			OR ISNULL(total, 0) != 0
			OR ISNULL(free_cons_amount, 0) != 0
			OR ISNULL(netrefundamount, 0) != 0
			OR ISNULL(discountrefund, 0) != 0
			)
		AND tbl.SchemeId = ISNULL(@SchemeId, tbl.SchemeId)
END