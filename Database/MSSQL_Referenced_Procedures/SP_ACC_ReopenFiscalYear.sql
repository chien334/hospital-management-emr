Create PROCEDURE [dbo].[SP_ACC_ReopenFiscalYear]
		@FiscalYearId int,
		@EmployeeId int,
		@HospitalId INT,
		@Remark varchar(300)
	AS
	--EXEC [dbo].[SP_ACC_ReopenFiscalYear] @FiscalYearId = 2, @EmployeeId =1,@HospitalId=3
	
	/************************************************************************
	FileName: [SP_ACC_ReopenFiscalYear]
	CreatedBy/date: Nagesh /22'June2020
	Description: reopen fiscal year, add log into fiscalYearLog table and update ledger balance as per opened fiscalYear
	Change History
	S.No.    UpdatedBy/Date                        Remarks
	1       Nagesh /22'June2020						created script for reopen fiscal year, add log and update ledger balance
	
	*************************************************************************/
	BEGIN	
		IF(@FiscalYearId IS NOT NULL AND @EmployeeId IS NOT NULL AND @HospitalId IS NOT NULL) 
		BEGIN				  
		   BEGIN TRANSACTION;
				SAVE TRANSACTION MySavePoint;  
				BEGIN TRY
					--code is here
					--update fiscal year closed to open 
					Update ACC_MST_FiscalYears set IsClosed=0
					where FiscalYearId=@FiscalYearId and HospitalId=@HospitalId
					
					--add log into ACC_FiscalYear_Log table
					Insert into ACC_FiscalYear_Log(FiscalYearId, LogType, LogDetails, CreatedOn, CreatedBy,HospitalId)
					values(@FiscalYearId,'reopened',@Remark,GETDATE(),@EmployeeId,@HospitalId)
					
					--update ACC_Ledger opening balance by opened fiscal year opening balance from LedgerBalanceHistory table					
					Update ACC_Ledger
					set OpeningBalance=lbh.OpeningBalance,
					DrCr=lbh.OpeningDrCr from ACC_LedgerBalanceHistory lbh
					join ACC_Ledger l on lbh.LedgerId=l.LedgerId and lbh.FiscalYearId=@FiscalYearId and lbh.HospitalId=@HospitalId
					
					select *from ACC_MST_FiscalYears where FiscalYearId=@FiscalYearId and HospitalId=@HospitalId
				COMMIT TRANSACTION 
				END TRY
				BEGIN CATCH
					IF @@TRANCOUNT > 0
					BEGIN
						ROLLBACK TRANSACTION MySavePoint; -- rollback to MySavePoint
					END
				END CATCH	
		END		
	END