/****** Object:  Procedure [dbo].[I_SumStockIngredientProduction_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[I_SumStockIngredientProduction_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	--------------- Reset: Stock in table:IngredientPDJob ---------------
	UPDATE [MasterSmartFeed].[dbo].[IngredientProductionJob]
	SET [Stock] = 0 ;

	--------------- Calculate: Stock of each Ingredient in Weighting Bin ---------------
	SELECT A.[IngredientCode], B.[IngredientName], SUM(A.[Weight]) AS [Stock]
	INTO #CalStockWeightingBin
	FROM [MasterSmartFeed].[dbo].[BinIdentWeighing] AS A
	LEFT JOIN [MasterSmartFeed].[dbo].[IngredientProductionMaster] AS B
	ON A.[IngredientCode] = B.[IngredientCode]
	WHERE A.[IngredientCode] IS NOT NULL AND LEN(A.[IngredientCode]) >= 6 AND
		  A.[Weight] > 0 AND A.[Weight] IS NOT NULL
	GROUP BY A.[IngredientCode], B.[IngredientName] ;

	--------------- Clear: Stock_ton in Weighting Bin <= 0 equal to 0 ---------------
	UPDATE #CalStockWeightingBin
	SET [Stock] = 0
	WHERE [Stock] <= 0 ;

	--------------- Update: Stock_ton in Weighting Bin to table:IngredientPDJob ---------------
	UPDATE [MasterSmartFeed].[dbo].[IngredientProductionJob]
	SET [Stock] = B.[Stock]
	FROM  [MasterSmartFeed].[dbo].[IngredientProductionJob] AS A
	INNER JOIN #CalStockWeightingBin AS B
	ON A.[IngredientCode] = B.[IngredientCode]
	WHERE B.[Stock] > 0 ;

	-------------------- Drop: Temporary Teable --------------------
	DROP TABLE IF EXISTS #CalStockWeightingBin ;
END
