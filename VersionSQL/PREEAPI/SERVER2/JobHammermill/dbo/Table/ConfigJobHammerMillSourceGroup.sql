/****** Object:  Table [dbo].[ConfigJobHammerMillSourceGroup]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[ConfigJobHammerMillSourceGroup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableSourceBin] [nvarchar](50) NULL
) ON [PRIMARY]

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[RunStore_CreateViewJobHammerMillSourceGroup]
   ON [dbo].[ConfigJobHammerMillSourceGroup]
   AFTER UPDATE, INSERT, DELETE
AS 
BEGIN

	EXEC [JobHammermill].[dbo].[CreateViewJobHammerMillSourceGroup_ExecBy_Trigger]

END

ALTER TABLE [dbo].[ConfigJobHammerMillSourceGroup] ENABLE TRIGGER [RunStore_CreateViewJobHammerMillSourceGroup]
