/****** Object:  Procedure [dbo].[0_CalStockMinWeightingBin_ExecBy_Agent]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[0_CalStockMinWeightingBin_ExecBy_Agent]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	--------------- Parameter for Calculation : ตั้งค่า parameter เริ่มต้นในการคำนวณ Stock Min ---------------
	--Set Mixing Process initial parmeter
	DECLARE @MixingEff_tph INT = 15
	DECLARE @HourOnHand_hour INT = 2
	DECLARE @MininumTonPerDay INT = 700
	
	-- Select: ProductionDate for Calculation
	DECLARE @ProductionDate DATE ;
	DECLARE @LimitDate INT = -90	-- **ปรับจำนวนย้อนหลังในการเรียกรายงาน (*default: 30)

	;WITH SelectProductionDate AS
	(
		SELECT TOP(1) [ProductionLine], [ProductionDate], SUM([ProductionWeight])/1000 AS [ProductionVolume_ton]  
		FROM [MasterPlantControl].[dbo].[BatchProduction]
		WHERE [ProductionDate] > DATEADD(DAY, @LimitDate,GETDATE()) 
		GROUP BY [ProductionLine], [ProductionDate]
		HAVING SUM([ProductionWeight])/1000 >= @MininumTonPerDay
	)
	SELECT * INTO #SelectProductionDate FROM SelectProductionDate ORDER BY [ProductionDate] DESC ;

	SET @ProductionDate = (SELECT [ProductionDate] FROM #SelectProductionDate)

	-- Calculate: TotalBatch and ProductionVolume
	DECLARE @TotalBatch_no INT ;
	DECLARE @ProductionVolume_ton DECIMAL(8, 2)

	SET @TotalBatch_no = (SELECT COUNT(*) FROM [MasterPlantControl].[dbo].[BatchProduction] WHERE [ProductionDate] = @ProductionDate)
	SET @ProductionVolume_ton = (SELECT SUM([ProductionWeight])/1000 FROM [MasterPlantControl].[dbo].[BatchProduction] WHERE [ProductionDate] = @ProductionDate)


	------------------------- Calulate Usages from Mixing Report : คำนวณหา Usage การใช้งานวัตถุดิบของถังเตรียมผสม -------------------------
	-- Select: WeighingBin for calulate StockMin
	SELECT A.[BinIO], C.[BinName], A.[ScaleIndex], A.[IngredientCode], B.[IngredientName], A.[Density] *C.[TotalVolume] AS [BinMaxWeight_ton]
	INTO #SelectWeighingBinForCalStockMin
	FROM [MasterSmartFeed].[dbo].[BinIdentWeighing] AS A
	LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionMaster] AS B
	ON A.[IngredientCode] COLLATE DATABASE_DEFAULT = B.[IngredientCode] COLLATE DATABASE_DEFAULT
	LEFT JOIN [MasterSmartFeed].[dbo].[BinMaster] AS C
	ON A.[BinIO] = C.[BinIO] AND A.[ScaleIndex] = C.[ScaleIndex]
	ORDER BY A.[BinIO]

	;WITH CalUsageReport AS
	(
	SELECT [BinNumber]
		  ,[IngredientCode]
		  ,[IngredientName]
		  ,MAX([ActualWeight]) AS [MaxUsagePerBatch_kg]
		  ,SUM([ActualWeight]) AS [DailyUsage_kg]
		  ,COUNT([ActualWeight]) AS [FrequencyOfUse_no]
		  ,CONVERT(DECIMAL(8, 2), CONVERT(DECIMAL(8, 2), COUNT([ActualWeight])) / @TotalBatch_no * 100) AS [FrequencyOfUse_%]
	FROM [MasterPlantControl].[dbo].[BatchIngredient]
	WHERE [ProductionDate] = @ProductionDate
	GROUP BY [BinNumber], [IngredientCode], [IngredientName]
	),
	SetDataForCalWeightedAverageUsagePerBatch AS
	(
		SELECT  [BinNumber]
			   ,[IngredientCode]
			   ,[IngredientName]
			   ,[ActualWeight]
			   ,COUNT([ActualWeight]) AS [CountFactor_no]
			   ,[ActualWeight] * COUNT([ActualWeight]) AS [MultiplyNumberFactor]
		FROM [MasterPlantControl].[dbo].[BatchIngredient]
		WHERE [ProductionDate] = @ProductionDate
		GROUP BY [IngredientCode], [IngredientName], [BinNumber], [ActualWeight]
	),
	CalWeightedAverageUsagePerBatch AS
	(
		SELECT  [BinNumber]
			   ,[IngredientCode]
			   ,[IngredientName]
			   ,SUM([CountFactor_no]) AS [SumCountFactor_no]
			   ,SUM([MultiplyNumberFactor]) AS [MultiplyNumberFactor]
			   ,CONVERT( DECIMAL(8, 2), SUM([MultiplyNumberFactor]) / SUM([CountFactor_no]) ) AS [WeightedAverageUsagePerBatch_kg]
		FROM SetDataForCalWeightedAverageUsagePerBatch
		GROUP BY [IngredientCode], [IngredientName], [BinNumber]
	)
	SELECT A.[BinNumber], A.[IngredientCode], A.[IngredientName], A.[WeightedAverageUsagePerBatch_kg]/1000 AS [WeightedAverageUsagePerBatch_ton], 
		   B.[MaxUsagePerBatch_kg]/1000 AS [MaxUsagePerBatch_ton], B.[DailyUsage_kg]/1000 AS [DailyUsage_ton], 
		   B.[FrequencyOfUse_no], B.[FrequencyOfUse_%]
	INTO #CalIngredientUsage
	FROM CalWeightedAverageUsagePerBatch AS A
	LEFT JOIN CalUsageReport AS B
	ON A.[BinNumber] = B.[BinNumber] AND A.[IngredientCode] = B.[IngredientCode]
	ORDER BY [BinNumber]


	SELECT A.[BinIO], A.[BinName], B.[BinNumber], A.[IngredientCode], A.[IngredientName], A.[BinMaxWeight_ton],
			B.[WeightedAverageUsagePerBatch_ton], B.[MaxUsagePerBatch_ton], B.[DailyUsage_ton], 
			B.[FrequencyOfUse_no], B.[FrequencyOfUse_%]
	INTO #IngredientUsageWeightingBin
	FROM #SelectWeighingBinForCalStockMin AS A
	LEFT JOIN #CalIngredientUsage AS B
	ON A.[BinName] COLLATE DATABASE_DEFAULT = B.[BinNumber] COLLATE DATABASE_DEFAULT AND 
		A.[IngredientCode] COLLATE DATABASE_DEFAULT = B.[IngredientCode] COLLATE DATABASE_DEFAULT
	ORDER BY A.[BinIO]


	--Insert Ingredient Usages of each WeighingBin to temp table:tmpUsageWeightingBin
	DELETE FROM [MasterSmartFeed].[dbo].[tmpUsageWeightingBin]

	INSERT INTO [MasterSmartFeed].[dbo].[tmpUsageWeightingBin]
		SELECT  [BinIO]
			   ,[IngredientCode]
			   ,[IngredientName]
			   ,[DailyUsage_ton]
			   ,[MaxUsagePerBatch_ton]
			   ,([MaxUsagePerBatch_ton] / [DailyUsage_ton]) * 24 AS [DayOnHand_hours]
			   ,[WeightedAverageUsagePerBatch_ton]
			   ,[FrequencyOfUse_no]
			   ,[FrequencyOfUse_%]
		FROM #IngredientUsageWeightingBin


	------------------------- Calculate StockMin Weighing Bin : คำนวณหา StockMin ของถังเตรียมผสมแต่ละใบ -------------------------
	-- Calculate: StockMin
	;WITH SetDataForCalculateStockMin AS
	(
		SELECT  [BinIO]
				,[IngredientCode]
				,[IngredientName]
				,[BinMaxWeight_ton]
				,[MaxUsagePerBatch_ton]
				,[WeightedAverageUsagePerBatch_ton]
				,[DailyUsage_ton]
				,[FrequencyOfUse_no]
				,[FrequencyOfUse_%]
		FROM #IngredientUsageWeightingBin
	),
	CalStockMin AS
	(
		SELECT   *
				,CASE
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour >= [BinMaxWeight_ton] THEN [BinMaxWeight_ton] * 0.85
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour >= [BinMaxWeight_ton]*0.75 THEN [BinMaxWeight_ton] * 0.85
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour >= [BinMaxWeight_ton]*0.75 THEN [BinMaxWeight_ton] * 0.85
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour >= [BinMaxWeight_ton]*0.50 THEN [BinMaxWeight_ton] * 0.75
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour >= [BinMaxWeight_ton]*0.25 THEN [BinMaxWeight_ton] * 0.50
					WHEN [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour < [BinMaxWeight_ton]*0.25 THEN [BinMaxWeight_ton] * 0.25
					WHEN [WeightedAverageUsagePerBatch_ton] IS NULL THEN [BinMaxWeight_ton] * 0.50
					END AS [Cal_StockMin_Ton]
		FROM SetDataForCalculateStockMin
	),
	SetStockMin AS
	(
		SELECT  *,
				CASE
					WHEN [Cal_StockMin_Ton] <= [DailyUsage_ton] THEN [Cal_StockMin_Ton]
					WHEN [Cal_StockMin_Ton] >= [DailyUsage_ton] AND [DailyUsage_ton] >= [BinMaxWeight_ton]*0.75 THEN [BinMaxWeight_ton]*0.75
					WHEN [Cal_StockMin_Ton] >= [DailyUsage_ton] AND [DailyUsage_ton] >= [BinMaxWeight_ton]*0.50 THEN [BinMaxWeight_ton]*0.50
					WHEN [Cal_StockMin_Ton] >= [DailyUsage_ton] AND [DailyUsage_ton] >= [BinMaxWeight_ton]*0.25 THEN [BinMaxWeight_ton]*0.25
					WHEN [Cal_StockMin_Ton] >= [DailyUsage_ton] AND [DailyUsage_ton] < [BinMaxWeight_ton]*0.25 THEN [BinMaxWeight_ton]*0.25
					WHEN [DailyUsage_ton] IS NULL THEN [BinMaxWeight_ton]*0.50
					END AS [Set_StockMin_Ton]
		FROM CalStockMin
	)
	SELECT * INTO #IngredientUsage FROM SetStockMin ;


	------------------------- Update StockMin by Bin to table:BinIdentWeighting -------------------------
	---------- START - Cursor: UpdateStockMinWeightingBin ----------
	-- Declare Variable for Cursor
	DECLARE @BinIO INT ;
	DECLARE @IngredientCodeWeighing NVARCHAR(50) ;
	DECLARE @StockMinWeightingBin INT ;

	DECLARE cursor_@UpdateStockMinWeightingBin CURSOR FOR
		SELECT [BinIO], [IngredientCode] ,[Set_StockMin_Ton] FROM #IngredientUsage ORDER BY [BinIO] ;

	-- Open Cursor
	OPEN cursor_@UpdateStockMinWeightingBin ;
	FETCH NEXT FROM cursor_@UpdateStockMinWeightingBin 
	INTO @BinIO, @IngredientCodeWeighing ,@StockMinWeightingBin ;

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			---------- Update StockMin by Bin ----------
			UPDATE [MasterSmartFeed].[dbo].[BinIdentWeighing]
			SET [StockMin] = @StockMinWeightingBin
			WHERE [BinIO] = @BinIO AND [IngredientCode] = @IngredientCodeWeighing

			--Reset @Variable, #TempTable before Fetch Next


	--Fetch next Cursor
			FETCH NEXT FROM cursor_@UpdateStockMinWeightingBin
			INTO @BinIO, @IngredientCodeWeighing ,@StockMinWeightingBin ;
		END

	--Close Cursor
	CLOSE cursor_@UpdateStockMinWeightingBin ;
	DEALLOCATE cursor_@UpdateStockMinWeightingBin ;

	---------- END - Cursor: UpdateStockMinWeightingBin ----------

	-- #################################################################################################### --

	------------------------- Calulate StockMin  of each Ingredient : คำนวณหา StockMin ของภาพรวมของวัตถุดิบแต่ละตัว -------------------------
	-- Calulate: WeightAverage Usage of each Ingredient
	;WITH SetDataForCalWeightedAverageUsagePerBatch AS
	(
		SELECT   [IngredientCode]
				,[IngredientName]
				,[ActualWeight]
				,COUNT([ActualWeight]) AS [CountFactor_no]
				,[ActualWeight] * COUNT([ActualWeight]) AS [MultiplyNumberFactor]
		FROM [MasterPlantControl].[dbo].[BatchIngredient]
		WHERE [ProductionDate] = @ProductionDate AND [IngredientCode] COLLATE DATABASE_DEFAULT IN (SELECT [IngredientCode] FROM [MasterSmartFeed].[dbo].[IngredientProductionJob])
		GROUP BY [IngredientCode], [IngredientName], [ActualWeight]
	),
	CalWeightedAverageUsagePerBatch AS
	(
		SELECT	 [IngredientCode]
				,[IngredientName]
				,SUM([CountFactor_no]) AS [SumCountFactor_no]
				,SUM([MultiplyNumberFactor]) AS [MultiplyNumberFactor]
				,CONVERT( DECIMAL(8, 2), SUM([MultiplyNumberFactor]) / SUM([CountFactor_no]) / 1000) AS [WeightedAverageUsagePerBatch_ton]
		FROM SetDataForCalWeightedAverageUsagePerBatch
		GROUP BY [IngredientCode], [IngredientName]
	)
	SELECT  [IngredientCode], [IngredientName], [WeightedAverageUsagePerBatch_ton]
	INTO #CalWeightedAverageUsagePerBatch
	FROM CalWeightedAverageUsagePerBatch

	-- Calculate: StockMin of each Ingredient
	SELECT *, [WeightedAverageUsagePerBatch_ton] * @MixingEff_tph * @HourOnHand_hour AS [StockMin_ton]
	INTO #CalStockMin
	FROM #CalWeightedAverageUsagePerBatch
	ORDER BY [IngredientCode]

	------------------------- Update StockMin to table:IngredeintPDJob -------------------------
	---------- START - Cursor: UpdateStockMinIngredient ----------
	-- Declare Variable for Cursor
	DECLARE @IngredientCode NVARCHAR(50)
	DECLARE @StockMin INT

	DECLARE cursor_@UpdateStockMinIngredient CURSOR FOR
		SELECT [IngredientCode], [StockMin_ton] FROM #CalStockMin

	-- Open Cursor
	OPEN cursor_@UpdateStockMinIngredient
	FETCH NEXT FROM cursor_@UpdateStockMinIngredient
	INTO @IngredientCode, @StockMin

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			---------- Update: StockMin bu Ingredient ----------
			UPDATE [MasterSmartFeed].[dbo].[IngredientProductionJob]
			SET [StockMin] = @StockMin
			WHERE [IngredientCode] = @IngredientCode

			--Reset @Variable, #TempTable before Fetch Next

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@UpdateStockMinIngredient
			INTO @IngredientCode, @StockMin ;
		END

	--Close Cursor
	CLOSE cursor_@UpdateStockMinIngredient ;
	DEALLOCATE cursor_@UpdateStockMinIngredient ;

	---------- END - Cursor: UpdateStockMinByIngredient ----------

	-- #################################################################################################### --

	------------------------- Calculate StockMin for PreWeighing Bin : คำนวณค่า StockMin ให้กับวัตถุดิบที่อยู่ในถัง PreWeighing -------------------------
	--Select StockMin from Weighing Bin
	;WITH [CTE_SelectMaxStockMin] AS
	(
		SELECT [IngredientCode], MAX([StockMin]) AS [StockMin]
		FROM [MasterSmartFeed].[dbo].[BinIdentWeighing]
		GROUP BY [IngredientCode]
	)
	SELECT A.[BinIO], A.[IngredientCode], A.[Density], B.[StockMin]
	INTO #SelectStockMin_WeighingStockMin
	FROM [MasterSmartFeed].[dbo].[BinIdentPreWeighing] AS A
	LEFT JOIN [CTE_SelectMaxStockMin] AS B 
	ON A.[IngredientCode] = B.[IngredientCode]
	WHERE B.[StockMin] IS NOT NULL

	--Set Data for Calculation
	SELECT A.[BinIO], A.[IngredientCode], C.[IngredientName], 
		   A.[Density], B.[TotalVolume], A.[Density] * B.[TotalVolume] AS [BinMaxWeight],
		   A.[StockMin] AS [StockMin_Weighing]
	INTO #PrepareForCalStockMin_PreWeighing
	FROM #SelectStockMin_WeighingStockMin AS A
	LEFT JOIN [MasterSmartFeed].[dbo].[BinMaster] AS B
	ON A.[BinIO] = B.[BinIO]
	LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionMaster] AS C
	ON A.[IngredientCode] = C.[IngredientCode]

	--Calculate StockMin PreWeighing
	SELECT *,
		   CASE 
				WHEN [StockMin_Weighing] > [BinMaxWeight] THEN [BinMaxWeight]*0.50
				ELSE [BinMaxWeight]*0.25
		   END AS [StockMin_PreWeighing]
	INTO #CalStockMin_PreWeighing
	FROM #PrepareForCalStockMin_PreWeighing

	--Reset StockMin PreWeighing Bin
	UPDATE [MasterSmartFeed].[dbo].[BinIdentPreWeighing]
	SET [StockMin] = 0

	--Update StockMin to PreWeighing Bin : อัพเดทค่า StockMin ให้กับวัตถุดิบที่อยู่ในถัง PreWeighing
	UPDATE [MasterSmartFeed].[dbo].[BinIdentPreWeighing]
	SET [StockMin] = #CalStockMin_PreWeighing.[StockMin_PreWeighing]
	FROM #CalStockMin_PreWeighing
	WHERE [MasterSmartFeed].[dbo].[BinIdentPreWeighing].[IngredientCode] = #CalStockMin_PreWeighing.[IngredientCode]
	
	-- #################################################################################################### --

	---------- Drop: Temporary Table ----------
	DROP TABLE IF EXISTS #SelectProductionDate
	DROP TABLE IF EXISTS #SelectWeighingBinForCalStockMin
	DROP TABLE IF EXISTS #CalIngredientUsage 														
	DROP TABLE IF EXISTS #IngredientUsageWeightingBin
	DROP TABLE IF EXISTS #IngredientUsage
	DROP TABLE IF EXISTS #CalWeightedAverageUsagePerBatch
	DROP TABLE IF EXISTS #CalStockMin
	DROP TABLE IF EXISTS #SelectStockMin_WeighingStockMin
	DROP TABLE IF EXISTS #PrepareForCalStockMin_PreWeighing
	DROP TABLE IF EXISTS #CalStockMin_PreWeighing
END
