/****** Object:  Table [dbo].[ConfigJobHammerMillDestinationGroup]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[ConfigJobHammerMillDestinationGroup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableDestinationBin] [nvarchar](50) NULL
) ON [PRIMARY]

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[RunStore_CreateViewJobHammerMillDestinationGroup]
   ON [dbo].[ConfigJobHammerMillDestinationGroup]
   AFTER UPDATE, INSERT, DELETE
AS 
BEGIN

	EXEC [JobHammermill].[dbo].[CreateViewJobHammerMillDestinationGroup_ExecBy_Trigger]

END

ALTER TABLE [dbo].[ConfigJobHammerMillDestinationGroup] ENABLE TRIGGER [RunStore_CreateViewJobHammerMillDestinationGroup]
