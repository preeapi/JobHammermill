/****** Object:  Procedure [dbo].[V_AddSource_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[V_AddSource_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	------------------------- Add SourceBin 1, 2 : เลือกถังต้นทางที่ถูกต้องให้กับ JobHammerMill -------------------------
	---------- START - Cursor: AddSource ----------
	-- Declare Variable for Cursor
	DECLARE @SequenceID INT ;
	DECLARE @IngredientCodePD NVARCHAR(50) ;
	DECLARE @LineCodeName NVARCHAR(20) ;
	DECLARE @NeedCheckLot INT ;
	DECLARE @LastFillingLot NVARCHAR(50) ;
	
	
	DECLARE cursor_@AddSource CURSOR FOR
		SELECT [SequenceID], [IngredientCodeDestination], [LineCodeName], [NeedCheckLot], [LastFillingLot]
		FROM [JobHammermill].[dbo].[JobSequenceHammerMill] ;

	-- Open Cursor
	OPEN cursor_@AddSource ;
	FETCH NEXT FROM cursor_@AddSource
	INTO @SequenceID, @IngredientCodePD, @LineCodeName, @NeedCheckLot, @LastFillingLot ;
	
	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			------------------------- Check: Source to Add -------------------------
			-- Check Same IngredientPD : ตรวจสอบวัตถุดิบที่ SameIngredient_PD
			;WITH CheckSameIngredientPD AS
			(
				SELECT [SameIngredientProductionCode]
				FROM [MasterSmartFeed].[dbo].[IngredientPDtoPD]
				WHERE [IngredientProductionCode] = @IngredientCodePD
			),
			-- Check IngredientPDtoRM : ตรวจสอบ Ingredient_RM ที่ตรงกับ Ingredient_PD และ SameIngredient_PD
			CheckIngredientRMtoPD AS
			(
				SELECT DISTINCT [IngredientRawMatCode]
				FROM [MasterSmartFeed].[dbo].[IngredientRMtoPD]
				WHERE [IngredientProductionCode] IN (@IngredientCodePD, (SELECT [SameIngredientProductionCode] FROM CheckSameIngredientPD))
			),
			-- Select SourceBin that have same Ingredient : เลือก SourceBin ถังตันทางที่มี วัตถุดิบที่ตรงกัน, Lot ตรงกัน, วัตถุดิบที่ SameCode และถังนั้นอนุญาติให้ดึงออก และสามารถลงได้ที่เครื่องบดเดียวกัน
			SelectSourceBin AS
				(
				SELECT A.[BinIO], A.[IngredientCode], B.[IngredientName], A.[BinPriority], A.[Weight] AS [BinWeight]
				FROM [JobHammermill].[dbo].[View_JobHammerMillSourceGroup] AS A
				LEFT JOIN [MasterSmartFeed].[dbo].[IngredientRawMatMaster] AS B
				ON A.[IngredientCode] = B.[IngredientCode]
				LEFT JOIN [MasterSmartFeed].[dbo].[SourceSetup] AS C
				ON A.[BinIO] = C.[BinIO]
				WHERE	A.[IngredientCode] IN ((SELECT [IngredientRawMatCode] FROM CheckIngredientRMtoPD)) AND
						((@NeedCheckLot = 1 AND A.[LastFillingLot] = @LastFillingLot) OR @NeedCheckLot = 0) AND
						A.[BinUse] = 1 AND A.[ActiveDischarge] = 1 AND
						C.[LineCodeName] = @LineCodeName
			)
			--Priority SourceBin by BinPriority, BinWeight : จัดลำดับวามสำคัญของ SourceBin จาก BinPriority และ BinWeight ตามลำดับ
			SELECT ROW_NUMBER() OVER(ORDER BY [BinPriority] ASC, [BinWeight] ASC) AS [ID], *
			INTO #PrioritySourceBin
			FROM SelectSourceBin
			ORDER BY [ID]


			------------------------- Update: SoruceBin to table:JobSequencHammerMill : อัพเดทถังต้นทาง SourceBin 1-2 ที่สามารถลงวัตถุดิบได้เพิ่มใน Job -------------------------
			DECLARE @Source1 INT = COALESCE((SELECT [BinIO] FROM #PrioritySourceBin WHERE [ID] = 1), 0) ;
			DECLARE @Source2 INT = COALESCE((SELECT [BinIO] FROM #PrioritySourceBin WHERE [ID] = 2), 0) ;
			DECLARE @IngredientCodeSource NVARCHAR(50) = COALESCE((SELECT [IngredientCode] FROM #PrioritySourceBin WHERE [ID] = 1), '0') ;
			DECLARE @IngredientNameSource NVARCHAR(100) = COALESCE((SELECT [IngredientName] FROM #PrioritySourceBin WHERE [ID] = 1), '0') ;

			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [Source1] = @Source1,
				[Source2] = @Source2,
				[IngredientCodeSource] = @IngredientCodeSource,
				[IngredientNameSource] = @IngredientNameSource
			WHERE [SequenceID] = @SequenceID
			
			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #PrioritySourceBin ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@AddSource
			INTO @SequenceID, @IngredientCodePD, @LineCodeName, @NeedCheckLot, @LastFillingLot ;
		END

	--Close Cursor
	CLOSE cursor_@AddSource ;
	DEALLOCATE cursor_@AddSource ;

	--------------- END - Cursor: AddSource ---------------
END
