/****** Object:  Procedure [dbo].[0_SetHammerMillLinePriority_ExecBy_Agent]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[0_SetHammerMillLinePriority_ExecBy_Agent]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	------------------------- Calulate: JobHammerMill Data from  Report -------------------------
	DECLARE @ReportStartTime NVARCHAR(20) = CONCAT(CONVERT(NVARCHAR(20),  DATEADD(DAY, -15, GETDATE())), ' ', '08:00:00') ;
	DECLARE @ReportStopTime NVARCHAR(20) = CONCAT(CONVERT(NVARCHAR(20), DATEADD(DAY, -1, GETDATE())), ' ', '07:59:59') ;

	SELECT [IngredientCode],
		   [IngredientName],
		   [LineCodeName],
		   AVG([UnitPerTon]) AS [EnergyConsumption_unitperton],
		   AVG([TonPerHour]) AS [Efficiency_tph],
		   COUNT([LineCodeName]) AS [FrequencyOfUse_times]
	INTO #CalJobHammerMillReport
	FROM [ReportHammermill].[dbo].[JobHammermillHeader]
	WHERE [JobStartTime] BETWEEN '2024-02-14' AND '2024-03-01' -- *เปลี่ยนเป็น @ReportStartTime, @ReportStopTime เมื่อรายงานอัพเดท
	GROUP BY [IngredientCode], [IngredientName], [LineCodeName] ;


	------------------------- Sequence and Update HammerMill LinePriority of each Ingredient to table:IngredientPDJob -------------------------
	---------- START Cursor: SequenceUpdateHammerMillLinePriority ----------
	-- Declare Variable for Cursor
	DECLARE @IngredientCodePD NVARCHAR(50) ;

	DECLARE cursor_@SequenceUpdateHammerMillLinePriority CURSOR FOR
		SELECT DISTINCT [IngredientCode] FROM #CalJobHammerMillReport ;

	-- Open Cursor
	OPEN cursor_@SequenceUpdateHammerMillLinePriority ;
	FETCH NEXT FROM cursor_@SequenceUpdateHammerMillLinePriority
	INTO @IngredientCodePD ;

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			---------- Sequence: HammerMillLinePriority by Ingredient ----------
			SELECT ROW_NUMBER() OVER(ORDER BY [EnergyConsumption_unitperton] ASC, [Efficiency_tph] DESC, [FrequencyOfUse_times] DESC) AS [ID]
				  ,[IngredientCode]
			      ,[IngredientName]
			      ,[LineCodeName] 
				  ,[EnergyConsumption_unitperton]
				  ,[Efficiency_tph]
				  ,[FrequencyOfUse_times]
			INTO #tempJobHammerMillReport
			FROM #CalJobHammerMillReport
			WHERE [IngredientCode] = @IngredientCodePD ;

			---------- Update: HammerMillLinePriority 1-4 to table:IngredientPDJob ----------
			UPDATE [MasterSmartFeed].[dbo].[IngredientProductionJob]
			SET [LinePriority1] = COALESCE((SELECT [LineCodeName] FROM #tempJobHammerMillReport WHERE [ID] = 1), '-'),
				[LinePriority2] = COALESCE((SELECT [LineCodeName] FROM #tempJobHammerMillReport WHERE [ID] = 2), '-'),
				[LinePriority3] = COALESCE((SELECT [LineCodeName] FROM #tempJobHammerMillReport WHERE [ID] = 3), '-'),
				[LinePriority4] = COALESCE((SELECT [LineCodeName] FROM #tempJobHammerMillReport WHERE [ID] = 4), '-')
			WHERE [IngredientCode] = @IngredientCodePD ;

			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #tempJobHammerMillReport ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@SequenceUpdateHammerMillLinePriority
			INTO @IngredientCodePD ;	
		END

	--Close Cursor
	CLOSE cursor_@SequenceUpdateHammerMillLinePriority ;
	DEALLOCATE cursor_@SequenceUpdateHammerMillLinePriority ;

	---------- END_Cursor: UpdateTRLinePriority ----------


	---------- Drop: Temporary Teable ----------
	DROP TABLE IF EXISTS #CalJobHammerMillReport ;
END
