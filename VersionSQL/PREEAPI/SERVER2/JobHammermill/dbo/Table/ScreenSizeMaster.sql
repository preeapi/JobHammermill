/****** Object:  Table [dbo].[ScreenSizeMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[ScreenSizeMaster](
	[ScreenSizeID] [int] NOT NULL,
	[ScreenSizeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ScreenSizeMaster] PRIMARY KEY CLUSTERED 
(
	[ScreenSizeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
