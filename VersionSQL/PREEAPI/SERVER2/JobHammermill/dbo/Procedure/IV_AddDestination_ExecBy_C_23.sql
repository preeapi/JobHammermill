/****** Object:  Procedure [dbo].[IV_AddDestination_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IV_AddDestination_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	------------------------- Select DestinationBin 2, 3, 4 : เลือกถังปลายทางที่ถูกต้องเพิ่มเติมจาก Destination1 -------------------------
	---------- START - Cursor: AddDestination ----------
	-- Declare Variable for Cursor
	DECLARE @SequenceID INT
	DECLARE @IngredientCode_PD NVARCHAR(50)
	DECLARE @LineCodeName NVARCHAR(10)
	DECLARE @Destination1 INT
	DECLARE @NeedCheckLot INT
	DECLARE @LastFillingLot NVARCHAR(50)

	DECLARE cursor_@AddDestination CURSOR FOR
		SELECT [SequenceID], [IngredientCodeDestination], [LineCodeName], [Destination1], [NeedCheckLot] ,[LastFillingLot]
		FROM [JobHammermill].[dbo].[JobSequenceHammerMill]
		WHERE [LineCodeName] <> '0'
	
	-- Open Cursor
	OPEN cursor_@AddDestination
	FETCH NEXT FROM cursor_@AddDestination
	INTO @SequenceID, @IngredientCode_PD, @LineCodeName, @Destination1, @NeedCheckLot, @LastFillingLot
	
	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			------------------------- Check: Destination to Add -------------------------
			-- Check Same IngredientPD : ตรวจสอบวัตถุดิบที่ Same Ingredient_PD
			;WITH CheckSameIngredientPD AS 
			(
				SELECT [SameIngredientProductionCode]
				FROM [MasterSmartFeed].[dbo].[IngredientPDtoPD]
				WHERE [IngredientProductionCode] = @IngredientCode_PD
			),	
			-- Select Destination that have same Ingredient : เลือก Destination ถังปลายทางที่มี วัตถุดิบที่ตรงกัน, Lot ตรงกัน, วัตถุดิบที่ SameCode, ถังนั้นอนุญาติให้เติม และสามารถบดจากเครื่องบดเดียวกัน
			SelectDestinationBin AS
			(
				SELECT A.[BinIO], A.[IngredientCode], A.[Weight], A.[BinPriority], @NeedCheckLot AS [NeedCheckLot], A.[LastFillingLot]
				FROM [JobHammermill].[dbo].[View_JobHammerMillDestinationGroup] AS A
				LEFT JOIN [MasterSmartFeed].[dbo].[DestinationSetup] AS B
				ON A.BinIO = B.BinIO
				WHERE	A.[BinIO] <> @Destination1 AND 
						((@NeedCheckLot = 1 AND A.[LastFillingLot] = @LastFillingLot) OR @NeedCheckLot = 0) AND
						A.[IngredientCode] IN (@IngredientCode_PD, (SELECT [SameIngredientProductionCode] FROM CheckSameIngredientPD)) AND
						A.[BinUse] = 1 AND A.[ActiveFilling] = 1 AND
						B.[LineCodeName] = @LineCodeName 
			),
			--  Priority Additional Destination by JobPriority, BinPriority, BinWeight : จัดลำดับวามสำคัญของ Destination จาก JobSequencePriority, BinPriority และ BinWeight ตามลำดับ
			PriorityDestinationBin AS
			(
				SELECT	ROW_NUMBER() OVER(ORDER by B.[JobPriority] ASC, A.[BinPriority] ASC, A.[Weight] DESC) AS [ID],
						A.[BinIO],
						COALESCE(B.[JobPriority], 10) AS [JobPriority],
						A.[BinPriority],
						A.[Weight] AS [BinWeight],
						COALESCE(B.[JobMain], 1) AS [JobMain]
				FROM SelectDestinationBin AS A
				LEFT JOIN [JobHammermill].[dbo].[JobSequenceHammerMill] AS B
				ON A.[BinIO] = B.[Destination1]
				LEFT JOIN [MasterSmartFeed].[dbo].[BinMaster] AS C
				ON A.[BinIO] = C.[BinIO] 
			)
			SELECT * INTO #AdditionalDestinationBin FROM PriorityDestinationBin


			------------------------- Update: Additional Destination to table:JobSequencHammerMill : อัพเดทถังปลายทาง Destination 2-4 ที่สามารถลงวัตถุดิบได้เพิ่มใน Job ------------------------- 
			DECLARE @Destination2 INT = (SELECT [BinIO] FROM #AdditionalDestinationBin WHERE [ID] = 1)
			DECLARE @Destination3 INT = (SELECT [BinIO] FROM #AdditionalDestinationBin WHERE [ID] = 2)
			DECLARE @Destination4 INT = (SELECT [BinIO] FROM #AdditionalDestinationBin WHERE [ID] = 3)

			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [Destination2] = COALESCE(@Destination2, 0),
				[Destination3] = COALESCE(@Destination3, 0),
				[Destination4] = COALESCE(@Destination4, 0)
			WHERE [SequenceID] = @SequenceID

			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #AdditionalDestinationBin

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@AddDestination
			INTO @SequenceID, @IngredientCode_PD, @LineCodeName, @Destination1, @NeedCheckLot, @LastFillingLot ;
		END

	--Close Cursor
	CLOSE cursor_@AddDestination ;
	DEALLOCATE cursor_@AddDestination ;

	--------------- END - Cursor: AddDestination ---------------
END
