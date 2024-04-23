/****** Object:  Table [dbo].[ScreenSizeMapping]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[ScreenSizeMapping](
	[ScreenSizeIDMapping] [int] IDENTITY(1,1) NOT NULL,
	[ScreenSizeDown] [int] NOT NULL,
	[ScreenSizeUp] [int] NOT NULL,
 CONSTRAINT [PK_ScreenSizeMapping] PRIMARY KEY CLUSTERED 
(
	[ScreenSizeDown] ASC,
	[ScreenSizeUp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ScreenSizeMapping]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenSizeDown] FOREIGN KEY([ScreenSizeDown])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ON DELETE CASCADE
ALTER TABLE [dbo].[ScreenSizeMapping] CHECK CONSTRAINT [ScreenSizeIDtoScreenSizeDown]
ALTER TABLE [dbo].[ScreenSizeMapping]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenSizeUp] FOREIGN KEY([ScreenSizeUp])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ALTER TABLE [dbo].[ScreenSizeMapping] CHECK CONSTRAINT [ScreenSizeIDtoScreenSizeUp]
