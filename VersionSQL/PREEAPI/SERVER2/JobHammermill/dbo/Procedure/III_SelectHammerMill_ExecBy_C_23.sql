/****** Object:  Procedure [dbo].[III_SelectHammerMill_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[III_SelectHammerMill_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	------------------------- Check HammerMill Status : ตรวจสอบความพร้อมใช้งานและสถานะต่างๆของ Hammermill -------------------------
	-- Check HammerMill LineReady : ตรวจสอบสถานะของไลน์บด 
	-- เลือกเฉพาะ ไลน์ที่ไม่มีการ Repair เครื่องจักร (SafetyModeStatus = 1) และ อยู่ในโหมด Auto (JobModeStatus = 1)
	;WITH CheckLineReadyStatusHammerMill AS
	(
		SELECT  A.[LineCodeName],
				A.[LineReadyStatus],
				A.[MachineActiveStatus],
				B.[ScreenSizeForward],
				B.[ScreenSizeReverse],
				B.[HMDirection]
		FROM [MasterSmartFeed].[dbo].[LineActiveJob] AS A
		LEFT JOIN [JobHammermill].[dbo].[ScreenSizeStatus] AS B
		ON A.[LineCodeName] COLLATE DATABASE_DEFAULT = B.[LineCodeName] COLLATE DATABASE_DEFAULT
		WHERE A.[LineCodeName] LIKE 'HM%' AND A.[SafetyModeStatus] <> 1 AND A.[JobModeStatus] = 1
	)
	-- Check HammerMill Screen : ตรวจสอบขนาดตะแกรงของเครื่องบด
	, CheckStatusScreenHammerMill AS
	(
		SELECT	[LineCodeName],
				[LineReadyStatus],
				[MachineActiveStatus],
				CASE
					WHEN [HMDirection] = 1 THEN [ScreenSizeForward]
					WHEN [HMDirection] = 2 THEN [ScreenSizeReverse] 
				END AS [ScreenSizeDown],
				CASE
					WHEN [HMDirection] = 1 THEN [ScreenSizeReverse] 
					WHEN [HMDirection] = 2 THEN [ScreenSizeForward]
				END AS [ScreenSizeUP]
		FROM CheckLineReadyStatusHammerMill
	)
	SELECT * INTO #StatusHammerMills FROM CheckStatusScreenHammerMill ;


	------------------------- Check HammerMill JobStatus : ตรวจสอบ JobHammerMill ว่าต้องใช้งานเครื่องบดไหน ? ตะแกรงอะไร ? -------------------------
	---------- START - Cursor: SelectHammerMill_DuplicateJob ----------
	-- Declare Variable for Cursor
	DECLARE @IngredientCodeDestination NVARCHAR(50) ;
	DECLARE @Destination1 INT ;

	DECLARE cursor_@SelectHammerMill_DuplicateJob CURSOR FOR
		SELECT [IngredientCodeDestination], [Destination1]
		FROM [JobHammermill].[dbo].[JobSequenceHammerMill]
		WHERE [IngredientCodeDestination] <> '0' AND [JobMain] = 1 ;

	-- Open Cursor
	OPEN cursor_@SelectHammerMill_DuplicateJob ;
	FETCH NEXT FROM cursor_@SelectHammerMill_DuplicateJob 
	INTO @IngredientCodeDestination, @Destination1 ;

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN

			-- Select LinePriority HammerMill by Job : เลือกเครื่องบดของแต่ละวัตถุดิบที่ได้จัดลำดับไว้จากตาราง IngredientProductionJob
			CREATE TABLE #LinePriorityHammerMillbyJob
			(
				[ID] INT IDENTITY(1, 1),
				[LinePriorityHammerMill] NVARCHAR(10)
			) ;

			INSERT INTO #LinePriorityHammerMillbyJob
				SELECT [LinePriority1] FROM [MasterSmartFeed].[dbo].[IngredientProductionJob] WHERE [IngredientCode] = @IngredientCodeDestination ;
			INSERT INTO #LinePriorityHammerMillbyJob
				SELECT [LinePriority2] FROM [MasterSmartFeed].[dbo].[IngredientProductionJob] WHERE [IngredientCode] = @IngredientCodeDestination ;
			INSERT INTO #LinePriorityHammerMillbyJob
				SELECT [LinePriority3] FROM [MasterSmartFeed].[dbo].[IngredientProductionJob] WHERE [IngredientCode] = @IngredientCodeDestination ;
			INSERT INTO #LinePriorityHammerMillbyJob
				SELECT [LinePriority4] FROM [MasterSmartFeed].[dbo].[IngredientProductionJob] WHERE [IngredientCode] = @IngredientCodeDestination ;

			-- Check HammerMill and DestinationSeptUp : ตรวจสอบว่าไลน์เครื่องบดสามารถลงถังปลายทางได้หรือไม่  ? ----------
			SELECT [ID], [LinePriorityHammerMill]
			INTO #SelectLinePriorityHammerMill
			FROM #LinePriorityHammerMillbyJob AS A
			LEFT JOIN [MasterSmartFeed].[dbo].[DestinationSetup] AS B
			ON A.[LinePriorityHammerMill] COLLATE Thai_CI_AS = B.[LineCodeName]
			WHERE B.[BinIO] = @Destination1 ;

			-- Check HammerMill Condition : ตรวจสอบค่าสถานะต่างๆของเครื่องบดที่ไว้ set ไว้คู่กับวัตถุดิบ
			SELECT	A.[ID],
					A.[LinePriorityHammerMill],
					B.[ScreenSizeDown],
					B.[ScreenSizeUp],
					B.[RawMatDirectionID],
					B.[FeederHM],
					B.[RPMHM],
					B.[OpenSlideFeeder]
			INTO #StastusJobHammerMill
			FROM #SelectLinePriorityHammerMill AS A
			INNER JOIN [JobHammermill].[dbo].[IngredienttoMachine] AS B
			ON A.[LinePriorityHammerMill] COLLATE Database_Default = B.LineCodeName
			WHERE B.[IngredientCode] = @IngredientCodeDestination ;
	

			------------------------- Select HammerMill for Job : เลือกเครื่องบดที่เหมาะสมให้กับ JobHammerMill -------------------------
			;WITH SetDataForSelectHammerMill AS
			(
				SELECT A.[ID],
					   A.[LinePriorityHammerMill],
					   A.[ScreenSizeDown] AS [JobHM_ScreenSizeDown],
					   A.[ScreenSizeUp] AS [JobHM_ScreenSizeUp],
					   A.[RawMatDirectionID],
					   A.[FeederHM],
					   A.[RPMHM],
					   A.[OpenSlideFeeder],
					   B.[ScreenSizeDown] AS [HM_ScreenSizeDown],
					   B.[ScreenSizeUP] AS [HM_ScreenSizeUp],
					   B.[LineReadyStatus],
					   B.[MachineActiveStatus]
				FROM #StastusJobHammerMill AS A
				LEFT JOIN #StatusHammerMills AS B
				ON A.[LinePriorityHammerMill] COLLATE Thai_CI_AS = B.[LineCodeName]
			),
			SelectHammerMill AS
			(
				SELECT *,
					   CASE
							WHEN [LineReadyStatus] = 1 AND [MachineActiveStatus] = 0 AND [JobHM_ScreenSizeDown] = [HM_ScreenSizeDown] AND [JobHM_ScreenSizeUp] = [HM_ScreenSizeUp] THEN 1
							WHEN [LineReadyStatus] = 1 AND [MachineActiveStatus] = 0 AND [JobHM_ScreenSizeDown] = [HM_ScreenSizeUp] AND [JobHM_ScreenSizeUp] = [HM_ScreenSizeDown] THEN 2
							WHEN [LineReadyStatus] = 1 AND [MachineActiveStatus] = 1 AND [JobHM_ScreenSizeDown] = [HM_ScreenSizeDown] AND [JobHM_ScreenSizeUp] = [HM_ScreenSizeUp] THEN 3
							WHEN [LineReadyStatus] = 1 AND [MachineActiveStatus] = 1 AND [JobHM_ScreenSizeDown] = [HM_ScreenSizeUp] AND [JobHM_ScreenSizeUp] = [HM_ScreenSizeDown] THEN 4
							ELSE 5
					   END AS [HammerMillPriority]
				FROM SetDataForSelectHammerMill
			)
			SELECT * INTO #SelectHammerMill FROM SelectHammerMill ;


			------------------------- Update HammerMillLine to table:JobSequenceHammerMill -------------------------
			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [LineCodeName] = (SELECT TOP(1) [LinePriorityHammerMill] FROM #SelectHammerMill ORDER BY [HammerMillPriority] ASC, [ID] ASC),
				[RawMatDirectionID] = (SELECT TOP(1) [RawMatDirectionID] FROM #SelectHammerMill ORDER BY [HammerMillPriority] ASC, [ID] ASC),
				[FeederHM] = (SELECT TOP(1) [FeederHM] FROM #SelectHammerMill ORDER BY [HammerMillPriority] ASC, [ID] ASC),
				[RPMHM] = (SELECT TOP(1) [RPMHM] FROM #SelectHammerMill ORDER BY [HammerMillPriority] ASC, [ID] ASC)
			WHERE [IngredientCodeDestination] = @IngredientCodeDestination AND [Destination1] = @Destination1 ;


			------------------------- Create DuplicateJobHammerMill -------------------------
			-- Check HammerMill for DuplicateJob
			CREATE TABLE #DuplicateJobHammerMill
			(
				[ID] INT IDENTITY(1, 1),
				[DuplicateLinePriorityHammerMill] NVARCHAR(20)
			)
			INSERT INTO #DuplicateJobHammerMill ([DuplicateLinePriorityHammerMill])
				SELECT [LinePriorityHammerMill] AS [DuplicateLinePriorityHammerMill]
				FROM #SelectHammerMill
				WHERE [ID] <> (SELECT TOP(1) [ID] FROM #SelectHammerMill ORDER BY [HammerMillPriority] ASC, [ID] ASC) AND [HammerMillPriority] IN (1, 2) ;

			-- Declare Variable for DuplicateJob
			DECLARE @CountDuplicateJobHammerMill_no INT = (SELECT COUNT([DuplicateLinePriorityHammerMill]) FROM #DuplicateJobHammerMill)  ;
			DECLARE @i INT = 1 ;

			DECLARE @IngredientCodeDestination_DuplicateJob NVARCHAR(50) ;
			DECLARE @IngredientNameDestination_DuplicateJob NVARCHAR(100) ;
			DECLARE @LineCodeName_DuplicateJob NVARCHAR(20) ;
			DECLARE @Destination1_DuplicateJob INT ;
			DECLARE @RawMatDirectionID_DuplicateJob INT ;
			DECLARE @FeederHM_DuplicateJob INT ;
			DECLARE @RPMHM_DuplicateJob INT ;
			DECLARE @JobPriority_DuplicateJob INT ;
			DECLARE @TargetWeight_DuplicateJob DECIMAL(8, 2) ;
			DECLARE @NeedCheckLot_DuplicateJob INT ;
			DECLARE @LastFillingLot_DuplicateJob NVARCHAR(50) ;

			DECLARE @InsertID_DuplicateJob INT = (SELECT COUNT(*) FROM [JobHammermill].[dbo].[JobSequenceHammerMill] WHERE [IngredientCodeDestination] <> '0' OR LEN([IngredientCodeDestination]) > 2) ;

			-- Update DuplicateJob to table:JobSequenceHammerMill 
			WHILE (@i <= @CountDuplicateJobHammerMill_no)
			BEGIN
				-- Select HammerMill for DuplicateJob
				SELECT	@LineCodeName_DuplicateJob = [DuplicateLinePriorityHammerMill] 
				FROM #DuplicateJobHammerMill 
				WHERE [ID] = @i ;

				-- Copy JobHammerMill Data form JobMain		
				SELECT	@IngredientCodeDestination_DuplicateJob = [IngredientCodeDestination],
						@IngredientNameDestination_DuplicateJob = [IngredientNameDestination],
						@Destination1_DuplicateJob = [Destination1],
						@RawMatDirectionID_DuplicateJob = [RawMatDirectionID],
						@FeederHM_DuplicateJob = [FeederHM],
						@RPMHM_DuplicateJob = [RPMHM],
						@JobPriority_DuplicateJob = [JobPriority] + 1, -- เซ็ตให้ JobPriority ของ JobDuplicate มากกว่า JobMain อยู่ 1 เสมอ
						@TargetWeight_DuplicateJob = [TargetWeight],
						@NeedCheckLot_DuplicateJob = [NeedCheckLot],
						@LastFillingLot_DuplicateJob = [LastFillingLot]
				FROM [JobHammermill].[dbo].[JobSequenceHammerMill] 
				WHERE [IngredientCodeDestination] = @IngredientCodeDestination AND [Destination1] = @Destination1 AND [JobMain] = 1 ;
		
				-- Update DuplicateJob to the next SequenceID
				UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
				SET [IngredientCodeDestination] = @IngredientCodeDestination_DuplicateJob,
					[IngredientNameDestination] = @IngredientNameDestination_DuplicateJob,
					[Destination1] = @Destination1_DuplicateJob,
					[LineCodeName] = @LineCodeName_DuplicateJob,
					[RawMatDirectionID] = @RawMatDirectionID_DuplicateJob,
					[FeederHM] = @FeederHM_DuplicateJob,
					[RPMHM] = @RPMHM_DuplicateJob,
					[JobPriority] = @JobPriority_DuplicateJob,
					[JobMain] = 0, -- JobDuplicate จะมี JobPriority เป็น 0 เสมอ
					[TargetWeight] = @TargetWeight_DuplicateJob,
					[NeedCheckLot] = @NeedCheckLot_DuplicateJob,
					[LastFillingLot] = @LastFillingLot_DuplicateJob
				WHERE [SequenceID] = @InsertID_DuplicateJob + @i ;
		
				-- Set Variable for the next loop
				SET @i = @i + 1 ;
			END

			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #LinePriorityHammerMillbyJob ;
			DROP TABLE IF EXISTS #SelectLinePriorityHammerMill ;
			DROP TABLE IF EXISTS #StastusJobHammerMill ;
			DROP TABLE IF EXISTS #SelectHammerMill ;
			DROP TABLE IF EXISTS #DuplicateJobHammerMill ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@SelectHammerMill_DuplicateJob
			INTO @IngredientCodeDestination, @Destination1 ;	
		END

	--Close Cursor
	CLOSE cursor_@SelectHammerMill_DuplicateJob ;
	DEALLOCATE cursor_@SelectHammerMill_DuplicateJob ;

	---------- END - Cursor:SelectHammerMill_DuplicateJob ----------

	---------- Drop: Temporary Table ----------
	DROP TABLE IF EXISTS #StatusHammerMills ;
END
