/****** Object:  Procedure [dbo].[II_SequenceIngredientPriorityByDestinationBin_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[II_SequenceIngredientPriorityByDestinationBin_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	------------------------- Set Data for Sequence of Priority Ingredeint in WeightingBin -------------------------
	---------- Select Only Ingredient that need Grinding ----------
	SELECT A.[BinIO], 
		   A.[IngredientCode], 
		   C.[IngredientName], 
		   B.[TotalVolume] * A.[Density] AS [BinMaxWeight],
		   D.[StockMin] AS [IngPDJob_StockMin], 
		   D.[Stock] AS [IngPDJob_Stock],
		   E.[StockMin] AS [CalStockMin], 
		   E.[Weight] AS [BinStock],
		   F.[DayOnHand_hours], 
		   F.[DailyUsage_ton] AS [DailyUsage], 
		   F.[FrequencyOfUse_no], 
		   F.[FrequencyOfUse_%]
	INTO #DataForSequenceIngredientByBin
	FROM [JobHammermill].[dbo].[View_JobHammerMillDestinationGroup] AS A
	LEFT JOIN [MasterSmartFeed].[dbo].[BinMaster] AS B
	ON A.[BinIO] = B.[BinIO]
	LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionMaster] AS C
	ON A.[IngredientCode] COLLATE Database_Default = C.[IngredientCode] COLLATE Database_Default
	LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionJob] AS D
	ON A.[IngredientCode] COLLATE Database_Default = D.[IngredientCode] COLLATE Database_Default
	LEFT JOIN [MasterSmartFeed].[dbo].[BinIdentWeighing] AS E
	ON A.[BinIO] = E.[BinIO]
	LEFT JOIN [MasterSmartFeed].[dbo].[tmpUsageWeightingBin] AS F
	ON A.[BinIO] = F.[BinIO]
	WHERE A.[IngredientCode] COLLATE Database_Default IN (SELECT [IngredientCode] FROM [JobHammermill].[dbo].[IngredienttoMachine]) AND
		  A.[IngredientCode] COLLATE Database_Default IS NOT NULL AND LEN(A.[IngredientCode]) >= 6 AND
		  A.[BinUse] = 1 AND A.[ActiveFilling] = 1 AND
		  D.[LinePriority1] LIKE 'HM%' AND
		  A.[BinIO] IN (SELECT [BinIO] FROM [MasterSmartFeed].[dbo].[DestinationSetup] WHERE [LineCodeName] LIKE 'HM%') ;
	
	-- SetData for PreWeighing Bin
	SELECT A.[IngredientCode], A.[StockMin], A.[Weight],
		   B.[DayOnHand_hours], MAX(B.[DailyUsage_ton]) AS [DailyUsage_ton], B.[FrequencyOfUse_no], B.[FrequencyOfUse_%]
	INTO #SetDatafor_PreWeighing
	FROM [MasterSmartFeed].[dbo].[BinIdentPreWeighing] AS A
	LEFT JOIN [MasterSmartFeed].[dbo].[tmpUsageWeightingBin] AS B
	ON A.[IngredientCode] = B.[IngredientCode]
	GROUP BY A.[IngredientCode], A.[StockMin], A.[Weight], 
			 B.[DayOnHand_hours], B.[FrequencyOfUse_no], B.[FrequencyOfUse_%] ;

	UPDATE #DataForSequenceIngredientByBin
	SET [CalStockMin] = #SetDatafor_PreWeighing.[StockMin],
		[BinStock] = #SetDatafor_PreWeighing.[Weight],
		[DayOnHand_hours] = #SetDatafor_PreWeighing.[DayOnHand_hours],
		[DailyUsage] = #SetDatafor_PreWeighing.[DailyUsage_ton],
		[FrequencyOfUse_no] = #SetDatafor_PreWeighing.[FrequencyOfUse_no],
		[FrequencyOfUse_%] = #SetDatafor_PreWeighing.[FrequencyOfUse_%]
	FROM #SetDatafor_PreWeighing
	WHERE #DataForSequenceIngredientByBin.[IngredientCode] = #SetDatafor_PreWeighing.[IngredientCode] AND
		  #DataForSequenceIngredientByBin.[BinIO] IN (SELECT [BinIO] FROM [MasterSmartFeed].[dbo].[BinIdentPreWeighing]) ;

	-------------------------  Sequence Priority Ingredeint in WeightingBin -------------------------
	;WITH SetDataForSequenceIngredientByBin AS
	(
		SELECT [BinIO]
			  ,[IngredientCode]
			  ,[IngredientName]
			  ,[IngPDJob_StockMin]
			  ,[IngPDJob_Stock]
			  ,[BinMaxWeight]
			  ,[CalStockMin]
			  ,[BinStock]
			  ,[DayOnHand_hours]
			  ,[DailyUsage]
			  ,[FrequencyOfUse_no]
			  ,[FrequencyOfUse_%]
		FROM #DataForSequenceIngredientByBin 
	),
	SequenceIngredientByBin AS
	(
		SELECT *,
			CASE
				WHEN [BinStock] <= [CalStockMin] AND [IngPDJob_Stock] <= [IngPDJob_StockMin] AND [CalStockMin] > 0 THEN 1
				WHEN [BinStock] <= [CalStockMin] AND [IngPDJob_Stock] >= [IngPDJob_StockMin] AND [CalStockMin] > 0 THEN 2
				-- JobPriority 3, 4, 5 พิจารณาเอาไว้ใช้งานช่วง Off-Peak
				WHEN [BinStock] <= [BinMaxWeight]*0.50 AND [DayOnHand_hours] <= 8 AND [FrequencyOfUse_%] >= 20 THEN 3
				WHEN [BinStock] <= [BinMaxWeight]*0.50 AND [DayOnHand_hours] <= 16 AND [FrequencyOfUse_%] >= 20 THEN 4
				WHEN [BinStock] <= [BinMaxWeight]*0.50 AND [DayOnHand_hours] <= 24 AND [FrequencyOfUse_%] >= 20 THEN 5
				ELSE 10
			END AS [JobPriority]
		FROM SetDataForSequenceIngredientByBin
	)
	SELECT * INTO #SequenceIngredientByBin FROM SequenceIngredientByBin ;


	-------------------------  Calculate: Job TargetWeight -------------------------
	SELECT [BinIO], [IngredientCode], [IngredientName], [BinMaxWeight], [CalStockMin], [BinStock], [DailyUsage], [DayOnHand_hours], [FrequencyOfUse_%], [JobPriority]
		   ,CASE
				WHEN [JobPriority] IN (1, 2) AND [DailyUsage] >= [BinMaxWeight] THEN [BinMaxWeight] - [BinStock] -- เติมเต็มถัง
				WHEN [JobPriority] IN (1, 2) AND [DailyUsage] < [BinMaxWeight] THEN [DailyUsage] -- เติมแค่ยอดการใช้ประจำวัน
				WHEN [DailyUsage] IS NULL THEN [BinMaxWeight]*0.75 - [BinStock] -- เติมให้ถึง 3/4 ของถัง
				-- JobPriority 3, 4, 5 พิจารณาเอาไว้ใช้งานช่วง Off-Peak
				WHEN [JobPriority] IN (3, 4, 5) THEN [BinMaxWeight] - [BinStock] -- เติมเต็มถัง
				ELSE 0
			END AS [TargetWeight]
	INTO #JobSequencePriority_CalTargetWeight
	FROM #SequenceIngredientByBin ;


	------------------------- Update Job Data to table:JobSeqeunceHammerMill  -------------------------
	--------- Reset all data in table: JobSeqeunceHammerMill ----------
	UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
	SET	[IngredientCodeSource] = '0', [IngredientNameSource] = '0', [IngredientCodeDestination] = '0', [IngredientNameDestination] = '0', [LineCodeName] = '0', 
		[Source1] = 0, [Source2] = 0, [SourceRoute1] = 0, [SourceRoute2] = 0,
		[Destination1] = 0, [Destination2] = 0, [Destination3] = 0, [Destination4] = 0, [DestinationRoute1] = 0, [DestinationRoute2] = 0, [DestinationRoute3] = 0, [DestinationRoute4] = 0,
		[RawMatDirectionID] = 0, [FeederHM] = 0, [RPMHM] = 0, 
		[JobPriority] = 0, [JobMain] = 0, [TargetWeight] = 0, [LastFillingLot] = '0', [NeedCheckLot] = 0 ;

	--------- START Cursor: UpdateJobPriorityHammerMill  ----------
	-- Declare Variable for Cursor
	DECLARE @IngredientCode NVARCHAR(50) ;
	DECLARE @IngredientName NVARCHAR(100) ;
	DECLARE @BinIO INT ;
	DECLARE @JobPriority INT ;
	DECLARE @TargetWeight FLOAT ;
	DECLARE @NeedCheckLot BIT ;
	DECLARE @LastFillingLot NVARCHAR(100) ;
	
	DECLARE cursor_@UpdateJobPriorityHammerMill CURSOR FOR
		SELECT A.[IngredientCode], A.[IngredientName], A.[BinIO], A.[JobPriority], A.[TargetWeight], B.[NeedCheckLot], C.[LastFillingLot]
		FROM #JobSequencePriority_CalTargetWeight AS A
		LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionJob] AS B
		ON A.[IngredientCode] = B.[IngredientCode]
		LEFT JOIN [View_JobHammerMillDestinationGroup] AS C
		ON A.BinIO = C.[BinIO]
	    WHERE A.[JobPriority] <> 10
	    ORDER BY A.[JobPriority] ASC, A.[FrequencyOfUse_%] DESC ;

	DECLARE @i INT = 1 ;

	-- Open Cursor
	OPEN cursor_@UpdateJobPriorityHammerMill ;
	FETCH NEXT FROM cursor_@UpdateJobPriorityHammerMill
	INTO @IngredientCode, @IngredientName, @BinIO, @JobPriority, @TargetWeight, @NeedCheckLot, @LastFillingLot ;

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			---------- Update JobHammerMill data ----------
			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [IngredientCodeDestination] = @IngredientCode,
				[IngredientNameDestination] = @IngredientName,
				[Destination1] = @BinIO,
				[JobPriority] = @JobPriority,
				[TargetWeight] = @TargetWeight,
				[JobMain] = 1,
				[NeedCheckLot] = @NeedCheckLot,
				[LastFillingLot] = @LastFillingLot
			WHERE [SequenceID] = @i ;

	--Reset @Variable, #TempTable before Fetch Next
		SET @i = @i + 1 ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@UpdateJobPriorityHammerMill
			INTO @IngredientCode, @IngredientName, @BinIO, @JobPriority, @TargetWeight, @NeedCheckLot, @LastFillingLot ;	
		END

	--Close Cursor
	CLOSE cursor_@UpdateJobPriorityHammerMill ;
	DEALLOCATE cursor_@UpdateJobPriorityHammerMill ;

	--------------- END Cursor: UpdateJobPriorityHammerMill ---------------

	------------------------- Drop: Temp Table -------------------------
	DROP TABLE IF EXISTS #DataForSequenceIngredientByBin ;
	DROP TABLE IF EXISTS #SetDatafor_PreWeighing
	DROP TABLE IF EXISTS #SequenceIngredientByBin ;
	DROP TABLE IF EXISTS #JobSequencePriority_CalTargetWeight ;
END
