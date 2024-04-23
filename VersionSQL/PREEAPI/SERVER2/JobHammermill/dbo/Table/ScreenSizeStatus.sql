/****** Object:  Table [dbo].[ScreenSizeStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[ScreenSizeStatus](
	[LineCodeName] [nvarchar](20) NOT NULL,
	[ScreenSizeForward] [int] NOT NULL,
	[ScreenSizeReverse] [int] NOT NULL,
	[HMDirection] [nvarchar](10) NOT NULL,
	[ScreenSizeIDMapping] [int] NOT NULL,
 CONSTRAINT [PK_ScreenSizeStatus] PRIMARY KEY CLUSTERED 
(
	[LineCodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ScreenSizeStatus]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenReverse] FOREIGN KEY([ScreenSizeReverse])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ALTER TABLE [dbo].[ScreenSizeStatus] CHECK CONSTRAINT [ScreenSizeIDtoScreenReverse]
ALTER TABLE [dbo].[ScreenSizeStatus]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenSizeForward] FOREIGN KEY([ScreenSizeForward])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ON DELETE CASCADE
ALTER TABLE [dbo].[ScreenSizeStatus] CHECK CONSTRAINT [ScreenSizeIDtoScreenSizeForward]
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[Check_ScreensizeIDMapping]
   ON  [dbo].[ScreenSizeStatus] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @HMDirection INT
	DECLARE @HM_Name NVARCHAR(6)
	DECLARE @Screen_Forward INT
	DECLARE @Screen_Reverse INT
	DECLARE @Screen_ID INT

	SET @HM_Name = (SELECT LineCodeName FROM INSERTED)
	SET @HMDirection = (SELECT HMDirection FROM INSERTED)
	SET @Screen_Forward = (SELECT ScreenSizeForward FROM INSERTED)
	SET @Screen_Reverse = (SELECT ScreenSizeReverse FROM INSERTED)
	
	IF @HMDirection = 1 -- Screen UP
		BEGIN
			SET @Screen_ID = (SELECT [ScreenSizeIDMapping]
			FROM [JobHammermill].[dbo].[ScreenSizeMapping]
			WHERE [ScreenSizeDown] = @Screen_Forward
			AND [ScreenSizeUp] = @Screen_Reverse)
		END
	ELSE IF @HMDirection = 2 -- Screen Down 
		BEGIN
			SET @Screen_ID = (SELECT [ScreenSizeIDMapping]
			FROM [JobHammermill].[dbo].[ScreenSizeMapping]
			WHERE [ScreenSizeDown] = @Screen_Reverse
			AND [ScreenSizeUp] = @Screen_Forward)
		END

	UPDATE [JobHammermill].[dbo].[ScreenSizeStatus]
	SET ScreenSizeIDMapping = @Screen_ID
	WHERE LineCodeName = @HM_Name

    -- Insert statements for trigger here

END

ALTER TABLE [dbo].[ScreenSizeStatus] ENABLE TRIGGER [Check_ScreensizeIDMapping]
