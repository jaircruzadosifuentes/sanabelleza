USE [DBFisioterapiaClinica]
GO
/****** Object:  User [Produccion]    Script Date: 14/10/2023 17:34:34 ******/
CREATE USER [Produccion] FOR LOGIN [Produccion] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  UserDefinedFunction [dbo].[fu_return_current_age]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fu_return_current_age] (
	@v_birthdate DATE
)
RETURNS INT AS
BEGIN
	DECLARE @v_age INT
	SET @v_age = ((((365 * YEAR(GETDATE())) - (365 * (YEAR(@v_birthdate)))) + (MONTH(GETDATE()) - MONTH(@v_birthdate)) * 30 + (DAY(GETDATE()) - DAY(@v_birthdate))) / 365)
    RETURN @v_age
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fu_return_serie_or_number]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE FUNCTION [dbo].[fu_return_serie_or_number] (
	@type_document_id INT
	, @type_serie_or_number_return VARCHAR(1)
	, @type_transaction_sale_or_buyout AS VARCHAR(1)
	--, @type_document AS VARCHAR(10)
)
RETURNS VARCHAR(20) AS
BEGIN
	
	DECLARE @v_serie AS BIGINT = 0
	DECLARE @v_serie_return AS VARCHAR(20)
	DECLARE @v_numero BIGINT  = 0
	DECLARE @v_numero_return AS VARCHAR(20)
	DECLARE @v_abb_type_document AS VARCHAR(20)
	DECLARE @v_serie_number_return AS VARCHAR(20)

	SET @v_abb_type_document = (SELECT abbreviation FROM voucher_document WHERE id = @type_document_id)

	IF @type_serie_or_number_return = 'S'
	BEGIN
		DECLARE @v_serie_aumenta AS BIGINT = 0
		DECLARE @v_serie_trabajada AS VARCHAR(20)

		SET @v_serie = (
			SELECT 
				CASE WHEN mv.serie IS NULL THEN 0 ELSE MAX(REPLACE(mv.serie, @v_abb_type_document, '')) END AS serie
			FROM movement_sale_buyout mv
			INNER JOIN movement m ON m.id = mv.movement_id
			WHERE m.flag = 0 AND mv.voucher_document_id = @type_document_id AND mv.type_transaction = @type_transaction_sale_or_buyout
			GROUP BY mv.serie
			);

		SET @v_serie_trabajada = (
		CASE 
			WHEN @v_serie >= 1 AND @v_serie <= 99 THEN CONCAT(UPPER(@v_abb_type_document), '00', @v_serie)
			WHEN @v_serie >= 100 AND @v_serie <= 999 THEN CONCAT(UPPER(@v_abb_type_document), '', @v_serie - 1)
			ELSE CONCAT(UPPER(@v_abb_type_document), '001')
		END);

		SET @v_serie_aumenta = (
			SELECT MV.id FROM movement_sale_buyout mv WHERE mv.serie = @v_serie_trabajada AND mv.number >= 99999999 --tope para que aumente a otro correlativo
		) 
		IF @v_serie_aumenta > 0
		BEGIN
			SET @v_serie = @v_serie + 1
		END
		SET @v_serie_number_return = (
		CASE 
			WHEN @v_serie >= 1 AND @v_serie <= 99 THEN CONCAT(UPPER(@v_abb_type_document), '00', @v_serie)
			WHEN @v_serie >= 100 AND @v_serie <= 999 THEN CONCAT(UPPER(@v_abb_type_document), '', @v_serie - 1)
			ELSE CONCAT(UPPER(@v_abb_type_document), '001')
		END);
		--RETURN @v_serie_return
	END
	ELSE IF @type_serie_or_number_return = 'N'
	BEGIN
		SET @v_numero = (
			SELECT 
				MAX(mv.number) as numero
			FROM movement_sale_buyout mv
			INNER JOIN movement m ON m.id = mv.movement_id
			WHERE m.flag = 0 AND mv.voucher_document_id = @type_document_id AND mv.type_transaction = @type_transaction_sale_or_buyout
		) + 1;

		SET @v_serie_number_return = (
			CASE 
				WHEN @v_numero >= 1 AND @v_numero <= 9 THEN CONCAT('0000000', @v_numero) 
				WHEN @v_numero >= 10 AND @v_numero <= 99 THEN CONCAT('000000', @v_numero) 
				WHEN @v_numero >= 100 AND @v_numero <= 999 THEN CONCAT('00000', @v_numero)
				WHEN @v_numero >= 1000 AND @v_numero <= 9999 THEN CONCAT('0000', @v_numero)
				WHEN @v_numero >= 10000 AND @v_numero <= 99999 THEN CONCAT('000', @v_numero)
				WHEN @v_numero >= 100000 AND @v_numero <= 999999 THEN CONCAT('00', @v_numero)
				WHEN @v_numero >= 1000000 AND @v_numero <= 9999999 THEN CONCAT('0', @v_numero)
				ELSE CONCAT('0000000', 1)
		END);
	END
	RETURN @v_serie_number_return
END
GO
/****** Object:  UserDefinedFunction [dbo].[fu_return_system_hour]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fu_return_system_hour] (
	@hour_attention TIME
)
RETURNS VARCHAR(2) AS
BEGIN
	DECLARE @v_value VARCHAR(2)
	SET @v_value = (CASE 
						WHEN @hour_attention IS NULL THEN '' 
						WHEN @hour_attention < '12:00:00' THEN 'AM' ELSE 'PM'
					END)
    RETURN @v_value
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fu_return_value_config]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fu_return_value_config] (
	@v_key_name VARCHAR(40)
)
RETURNS VARCHAR(2000) AS
BEGIN
	DECLARE @v_value VARCHAR(2000)
	SET @v_value = (SELECT RTRIM(LTRIM(value)) FROM config WHERE [key_name] = @v_key_name)
    RETURN @v_value
END;
GO
/****** Object:  Table [dbo].[accounting_plan]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[accounting_plan](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](200) NULL,
	[accounting_code] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_accounting_plan] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[accounting_plan_detail]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[accounting_plan_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[accounting_plan_id] [int] NULL,
	[name] [varchar](200) NULL,
	[accouting_code] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_accounting_plan_detail] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[afp_sure]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[afp_sure](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](150) NULL,
	[abbreviation] [varchar](50) NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_afp_sure] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[area]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[area](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[description] [varchar](200) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_area] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[campus]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[campus](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
	[abbreviation] [varchar](50) NULL,
	[address] [varchar](150) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_campus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cash_register]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cash_register](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[campus_id] [int] NULL,
	[name] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [nchar](10) NULL,
 CONSTRAINT [PK_cash_register] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cash_register_detail]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cash_register_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[employeed_cash_register_id] [int] NULL,
	[closed_cash_register] [bit] NULL,
	[opened_amount] [decimal](18, 2) NULL,
	[opening_date] [datetime] NULL,
	[state] [bit] NULL,
	[closed_date] [datetime] NULL,
 CONSTRAINT [PK_cash_register_detail] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cash_register_detail_historic]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cash_register_detail_historic](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[cash_register_detail_id] [int] NULL,
	[opened_amount] [decimal](18, 2) NULL,
	[amount_outlay] [decimal](18, 2) NULL,
	[amount_sold] [decimal](18, 2) NULL,
	[amount_expected] [decimal](18, 2) NULL,
	[closed_cash_register] [bit] NULL,
	[opening_date] [datetime] NULL,
	[closed_date] [datetime] NULL,
 CONSTRAINT [PK_cash_register_detail_historic] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[charges_contract]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[charges_contract](
	[id] [int] NULL,
	[name] [varchar](150) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[clinic_history]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[clinic_history](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NULL,
	[weight] [decimal](18, 2) NULL,
	[has_disease] [bit] NULL,
	[disease_description] [varchar](300) NULL,
	[have_some_operation] [bit] NULL,
	[clinical_operation] [varchar](300) NULL,
	[physical_exploration] [varchar](3000) NULL,
	[pain_threshold] [int] NULL,
	[diagnosis] [varchar](3000) NULL,
	[take_some_medication] [bit] NULL,
	[medicines] [varchar](300) NULL,
	[file_archive] [varchar](200) NULL,
	[packet_or_unit_session_id] [int] NULL,
	[frecuency_id] [int] NULL,
	[clinic_history_code] [int] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_clinic_history] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[config]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[config](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[key_name] [varchar](40) NULL,
	[value] [varchar](2000) NULL,
 CONSTRAINT [PK_config] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[customer]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[person_id] [int] NULL,
	[customer_type] [varchar](1) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_customer] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[document]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[document](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
	[abbreviation] [varchar](20) NULL,
	[size] [int] NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_document] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[person_id] [int] NULL,
	[role_id] [int] NULL,
	[state] [char](1) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[employeed_code] [varchar](10) NULL,
	[user_access] [varchar](100) NULL,
	[password] [varchar](100) NULL,
	[token] [varchar](300) NULL,
	[admision_date] [datetime] NULL,
	[termination_date] [datetime] NULL,
	[afp_sure_id] [int] NULL,
	[associate_code] [varchar](50) NULL,
	[afp_link_date] [date] NULL,
	[type_contract_id] [int] NULL,
	[modality_id] [int] NULL,
	[contract_approval_date] [datetime] NULL,
	[pdf_contract] [varchar](150) NULL,
	[user_name] [varchar](50) NULL,
	[campus_id] [int] NULL,
 CONSTRAINT [PK_employeed] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed_cash_register]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed_cash_register](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[employeed_id] [int] NULL,
	[cash_register_id] [int] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_employeed_cash_register] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed_experience]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed_experience](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[company] [varchar](100) NULL,
	[still_works] [bit] NULL,
	[start_date] [date] NULL,
	[finish_date] [date] NULL,
	[activities] [varchar](3000) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[employeed_id] [int] NULL,
 CONSTRAINT [PK_employeed_experience] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed_login]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed_login](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[date_access] [datetime] NULL,
	[finish_date_access] [datetime] NULL,
	[state] [bit] NULL,
	[employeed_id] [int] NULL,
 CONSTRAINT [PK_employeed_login] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed_salary]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed_salary](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[salary] [decimal](18, 2) NULL,
	[state] [bit] NULL,
	[user_register] [varchar](4) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[employeed_id] [int] NULL,
 CONSTRAINT [PK_employeed_salary] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[employeed_state]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employeed_state](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[abbreviation] [char](1) NULL,
	[description] [varchar](100) NULL,
 CONSTRAINT [PK_employeed_state] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[frecuency]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[frecuency](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[description] [varchar](50) NULL,
	[abbreviation] [varchar](30) NULL,
	[value] [int] NULL,
	[created_at] [datetime] NULL,
	[modificaton_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_frecuency] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[message]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[message](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[message_content] [varchar](max) NULL,
	[from_id] [int] NULL,
	[to_id] [int] NULL,
	[type_user_to] [char](1) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[seen] [bit] NULL,
	[state] [bit] NULL,
	[type_user_from] [char](1) NULL,
	[seen_date] [datetime] NULL,
 CONSTRAINT [PK_message] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[modality_contract]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[modality_contract](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](150) NULL,
	[abbreviation] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_modality_contract] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[movement]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[movement](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[number_movement] [varchar](50) NULL,
	[description] [varchar](200) NULL,
	[code_movement] [varchar](10) NULL,
	[flag] [int] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_movement] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[movement_detail_employeed_cash_register]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[movement_detail_employeed_cash_register](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[movement_id] [int] NULL,
	[employeed_cash_register_id] [int] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_movement_detail_employeed_cash_register] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[movement_pay]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[movement_pay](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[payment_sche_way_id] [int] NULL,
	[state] [bit] NULL,
	[movement_id] [int] NULL,
 CONSTRAINT [PK_movement_pay] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[movement_sale_buyout]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[movement_sale_buyout](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[movement_id] [int] NULL,
	[sub_total] [decimal](18, 2) NULL,
	[igv] [decimal](18, 2) NULL,
	[total] [decimal](18, 2) NULL,
	[discount] [decimal](18, 2) NULL,
	[turned] [decimal](18, 2) NULL,
	[payment_method_id] [int] NULL,
	[serie] [varchar](20) NULL,
	[number] [varchar](20) NULL,
	[type_transaction] [varchar](1) NULL,
	[code_employeed] [varchar](4) NULL,
	[customer_id] [int] NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[voucher_document_id] [int] NULL,
 CONSTRAINT [PK_movement_sale_buyout] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[operation_accouting_plan]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[operation_accouting_plan](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[operation_type_id] [int] NULL,
	[accouting_plan_detail_id] [int] NULL,
	[accouting_type] [varchar](1) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_operation_accouting_plan] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[operation_type]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[operation_type](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](200) NULL,
	[operation_code] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_operation_type] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[option]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[option](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[component] [varchar](50) NULL,
	[name] [varchar](50) NULL,
	[icon] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_option] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[option_auth]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[option_auth](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[option_id] [int] NULL,
	[employeed_id] [int] NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_option_auth] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[option_items]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[option_items](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[component] [varchar](50) NULL,
	[name] [varchar](50) NULL,
	[to] [varchar](50) NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[option_id] [int] NULL,
	[orden] [int] NULL,
 CONSTRAINT [PK_option_items] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[option_items_auth]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[option_items_auth](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[option_items_id] [int] NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[option_auth_id] [int] NULL,
 CONSTRAINT [PK_option_items_auth] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[packets_or_unit_sessions]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[packets_or_unit_sessions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[description] [varchar](100) NULL,
	[created_at] [datetime] NULL,
	[number_sessions] [int] NULL,
	[cost_per_unit] [decimal](18, 2) NULL,
	[abbreviation] [varchar](50) NULL,
	[maximum_fees_to_pay] [int] NULL,
	[state] [bit] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_packets_or_unit_sessions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[person_id] [int] NULL,
	[save_to_draft] [bit] NULL,
	[state] [char](1) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[payment_schedule] [bit] NULL,
	[flag] [bit] NULL,
	[flag_date] [datetime] NULL,
	[user_name] [varchar](50) NULL,
	[user_access] [varchar](4) NULL,
	[password_access] [varchar](50) NULL,
 CONSTRAINT [PK_patient] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_progress_sesion]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_progress_sesion](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NULL,
	[session_number] [int] NULL,
	[session_date] [date] NULL,
	[session_hour] [time](7) NULL,
	[attended] [bit] NULL,
	[on_hold] [bit] NULL,
	[patient_progress_session_detail] [int] NULL,
	[employeed_id] [int] NULL,
	[lost_turn] [bit] NULL,
	[date_missed_turn] [datetime] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [char](1) NULL,
	[is_flag] [bit] NULL,
 CONSTRAINT [PK_patient_progress_sesion] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_progress_sesion_detail]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_progress_sesion_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[recommendation] [varchar](4000) NULL,
	[files] [varchar](200) NULL,
	[description] [varchar](4000) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[time_demoration] [time](7) NULL,
 CONSTRAINT [PK_patient_progress_sesion_detail] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_progress_sesion_state]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_progress_sesion_state](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[abbreviation] [char](1) NOT NULL,
	[description] [varchar](100) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_patient_progress_sesion_state] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_solicitude]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_solicitude](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[employeed_id] [int] NULL,
	[hour_attention] [time](7) NULL,
	[date_attention] [date] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[patient_id] [int] NULL,
	[finished] [bit] NULL,
	[date_finished] [datetime] NULL,
 CONSTRAINT [PK_patient_solicitude] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_state]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_state](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[abbreviation] [char](1) NULL,
	[description] [varchar](100) NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_patient_state] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[patient_state_historic]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_state_historic](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[created_at] [datetime] NULL,
	[patient_id] [int] NULL,
	[state] [char](1) NULL,
 CONSTRAINT [PK_patient_state_historic] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pay_method]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pay_method](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[description] [varchar](100) NULL,
	[abbreviation] [varchar](30) NULL,
	[created_at] [datetime] NULL,
	[state] [bit] NULL,
	[have_concept] [bit] NULL,
 CONSTRAINT [PK_pay_method] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[payment]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NULL,
	[sub_total] [decimal](18, 2) NULL,
	[igv] [decimal](18, 2) NULL,
	[total] [decimal](18, 2) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [char](1) NULL,
	[total_cancelled] [decimal](18, 2) NULL,
	[total_debt] [decimal](18, 2) NULL,
 CONSTRAINT [PK_payment] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[payment_schedule]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment_schedule](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[debt_number] [int] NULL,
	[amount] [decimal](18, 2) NULL,
	[payment_date] [date] NULL,
	[created_at] [datetime] NULL,
	[payment_date_canceled] [datetime] NULL,
	[payment_id] [int] NULL,
	[state] [bit] NULL,
	[user_payment] [varchar](4) NULL,
 CONSTRAINT [PK_payment_schedule] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[payment_schedule_way_to_pay]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment_schedule_way_to_pay](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[payment_schedule_id] [int] NULL,
	[pay_method_id] [int] NULL,
	[concept] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[cash] [decimal](18, 2) NULL,
	[monetary_exchange] [decimal](18, 2) NULL,
 CONSTRAINT [PK_payment_schedule_way_to_pay] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[payment_state]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment_state](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[abbreviation] [char](1) NULL,
	[description] [varchar](100) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_payment_state] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[person]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[person](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[names] [varchar](200) NULL,
	[surnames] [varchar](300) NULL,
	[profile_picture] [varchar](100) NULL,
	[birth_date] [date] NULL,
	[address] [varchar](100) NULL,
	[civil_status] [char](1) NULL,
	[gender] [char](1) NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
 CONSTRAINT [PK_person] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[person_cellphone]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[person_cellphone](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[number_cellphone] [varchar](15) NULL,
	[operator_id] [int] NULL,
	[is_default] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[person_id] [int] NULL,
 CONSTRAINT [PK_person_cellphone] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[person_document]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[person_document](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[person_id] [int] NULL,
	[number_document] [varchar](20) NULL,
	[created_at] [datetime] NULL,
	[state] [bit] NULL,
	[modification_date] [datetime] NULL,
	[document_id] [int] NULL,
	[is_default] [bit] NULL,
 CONSTRAINT [PK_person_document] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[person_email]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[person_email](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[person_id] [int] NULL,
	[email] [varchar](100) NULL,
	[created_at] [datetime] NULL,
	[state] [bit] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_person_email] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[role]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[role](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](75) NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[abbreviation] [varchar](75) NULL,
	[salary_to_pay] [decimal](18, 2) NULL,
	[area_id] [int] NULL,
	[modification_date] [datetime] NULL,
 CONSTRAINT [PK_role] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[routes]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[routes](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[path] [varchar](70) NULL,
	[exact] [bit] NULL,
	[name] [varchar](70) NULL,
	[element] [varchar](70) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[state] [bit] NULL,
	[special] [bit] NULL,
 CONSTRAINT [PK_routes] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[routes_auth]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[routes_auth](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[routes_id] [int] NULL,
	[state] [bit] NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[employeed_id] [int] NULL,
 CONSTRAINT [PK_routes_auth] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[type_of_contract]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[type_of_contract](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](150) NULL,
	[created_at] [datetime] NULL,
	[modification_date] [datetime] NULL,
	[abbreviation] [varchar](50) NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_type_of_contract] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[voucher_document]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[voucher_document](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
	[abbreviation] [varchar](20) NULL,
	[created_at] [datetime] NULL,
	[modificacion_date] [datetime] NULL,
	[state] [bit] NULL,
 CONSTRAINT [PK_voucher_document] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[accounting_plan_detail]  WITH CHECK ADD  CONSTRAINT [FK_accounting_plan_detail_accounting_plan] FOREIGN KEY([accounting_plan_id])
REFERENCES [dbo].[accounting_plan] ([id])
GO
ALTER TABLE [dbo].[accounting_plan_detail] CHECK CONSTRAINT [FK_accounting_plan_detail_accounting_plan]
GO
ALTER TABLE [dbo].[cash_register]  WITH CHECK ADD  CONSTRAINT [FK_cash_register_campus] FOREIGN KEY([campus_id])
REFERENCES [dbo].[campus] ([id])
GO
ALTER TABLE [dbo].[cash_register] CHECK CONSTRAINT [FK_cash_register_campus]
GO
ALTER TABLE [dbo].[cash_register_detail]  WITH CHECK ADD  CONSTRAINT [FK_cash_register_detail_employeed_cash_register] FOREIGN KEY([employeed_cash_register_id])
REFERENCES [dbo].[employeed_cash_register] ([id])
GO
ALTER TABLE [dbo].[cash_register_detail] CHECK CONSTRAINT [FK_cash_register_detail_employeed_cash_register]
GO
ALTER TABLE [dbo].[cash_register_detail_historic]  WITH CHECK ADD  CONSTRAINT [FK_cash_register_detail_historic_cash_register_detail] FOREIGN KEY([cash_register_detail_id])
REFERENCES [dbo].[cash_register_detail] ([id])
GO
ALTER TABLE [dbo].[cash_register_detail_historic] CHECK CONSTRAINT [FK_cash_register_detail_historic_cash_register_detail]
GO
ALTER TABLE [dbo].[clinic_history]  WITH CHECK ADD  CONSTRAINT [FK_clinic_history_frecuency] FOREIGN KEY([frecuency_id])
REFERENCES [dbo].[frecuency] ([id])
GO
ALTER TABLE [dbo].[clinic_history] CHECK CONSTRAINT [FK_clinic_history_frecuency]
GO
ALTER TABLE [dbo].[clinic_history]  WITH CHECK ADD  CONSTRAINT [FK_clinic_history_packets_or_unit_sessions] FOREIGN KEY([packet_or_unit_session_id])
REFERENCES [dbo].[packets_or_unit_sessions] ([id])
GO
ALTER TABLE [dbo].[clinic_history] CHECK CONSTRAINT [FK_clinic_history_packets_or_unit_sessions]
GO
ALTER TABLE [dbo].[clinic_history]  WITH CHECK ADD  CONSTRAINT [FK_clinic_history_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient] ([id])
GO
ALTER TABLE [dbo].[clinic_history] CHECK CONSTRAINT [FK_clinic_history_patient]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_afp_sure] FOREIGN KEY([afp_sure_id])
REFERENCES [dbo].[afp_sure] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_afp_sure]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_campus] FOREIGN KEY([campus_id])
REFERENCES [dbo].[campus] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_campus]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_modality_contract] FOREIGN KEY([modality_id])
REFERENCES [dbo].[modality_contract] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_modality_contract]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_person] FOREIGN KEY([person_id])
REFERENCES [dbo].[person] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_person]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_role] FOREIGN KEY([role_id])
REFERENCES [dbo].[role] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_role]
GO
ALTER TABLE [dbo].[employeed]  WITH CHECK ADD  CONSTRAINT [FK_employeed_type_of_contract] FOREIGN KEY([type_contract_id])
REFERENCES [dbo].[type_of_contract] ([id])
GO
ALTER TABLE [dbo].[employeed] CHECK CONSTRAINT [FK_employeed_type_of_contract]
GO
ALTER TABLE [dbo].[employeed_cash_register]  WITH CHECK ADD  CONSTRAINT [FK_employeed_cash_register_cash_register] FOREIGN KEY([cash_register_id])
REFERENCES [dbo].[cash_register] ([id])
GO
ALTER TABLE [dbo].[employeed_cash_register] CHECK CONSTRAINT [FK_employeed_cash_register_cash_register]
GO
ALTER TABLE [dbo].[employeed_cash_register]  WITH CHECK ADD  CONSTRAINT [FK_employeed_cash_register_employeed] FOREIGN KEY([employeed_id])
REFERENCES [dbo].[employeed] ([id])
GO
ALTER TABLE [dbo].[employeed_cash_register] CHECK CONSTRAINT [FK_employeed_cash_register_employeed]
GO
ALTER TABLE [dbo].[employeed_experience]  WITH CHECK ADD  CONSTRAINT [FK_employeed_experience_employeed] FOREIGN KEY([employeed_id])
REFERENCES [dbo].[employeed] ([id])
GO
ALTER TABLE [dbo].[employeed_experience] CHECK CONSTRAINT [FK_employeed_experience_employeed]
GO
ALTER TABLE [dbo].[employeed_login]  WITH CHECK ADD  CONSTRAINT [FK_employeed_login_employeed] FOREIGN KEY([employeed_id])
REFERENCES [dbo].[employeed] ([id])
GO
ALTER TABLE [dbo].[employeed_login] CHECK CONSTRAINT [FK_employeed_login_employeed]
GO
ALTER TABLE [dbo].[employeed_salary]  WITH CHECK ADD  CONSTRAINT [FK_employeed_salary_employeed] FOREIGN KEY([employeed_id])
REFERENCES [dbo].[employeed] ([id])
GO
ALTER TABLE [dbo].[employeed_salary] CHECK CONSTRAINT [FK_employeed_salary_employeed]
GO
ALTER TABLE [dbo].[movement_detail_employeed_cash_register]  WITH CHECK ADD  CONSTRAINT [FK_movement_detail_employeed_cash_register_movement] FOREIGN KEY([movement_id])
REFERENCES [dbo].[movement] ([id])
GO
ALTER TABLE [dbo].[movement_detail_employeed_cash_register] CHECK CONSTRAINT [FK_movement_detail_employeed_cash_register_movement]
GO
ALTER TABLE [dbo].[movement_pay]  WITH CHECK ADD  CONSTRAINT [FK_movement_pay_movement] FOREIGN KEY([movement_id])
REFERENCES [dbo].[movement] ([id])
GO
ALTER TABLE [dbo].[movement_pay] CHECK CONSTRAINT [FK_movement_pay_movement]
GO
ALTER TABLE [dbo].[movement_pay]  WITH CHECK ADD  CONSTRAINT [FK_movement_pay_payment_schedule_way_to_pay] FOREIGN KEY([payment_sche_way_id])
REFERENCES [dbo].[payment_schedule_way_to_pay] ([id])
GO
ALTER TABLE [dbo].[movement_pay] CHECK CONSTRAINT [FK_movement_pay_payment_schedule_way_to_pay]
GO
ALTER TABLE [dbo].[movement_sale_buyout]  WITH CHECK ADD  CONSTRAINT [FK_movement_sale_buyout_customer] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customer] ([id])
GO
ALTER TABLE [dbo].[movement_sale_buyout] CHECK CONSTRAINT [FK_movement_sale_buyout_customer]
GO
ALTER TABLE [dbo].[movement_sale_buyout]  WITH CHECK ADD  CONSTRAINT [FK_movement_sale_buyout_movement] FOREIGN KEY([movement_id])
REFERENCES [dbo].[movement] ([id])
GO
ALTER TABLE [dbo].[movement_sale_buyout] CHECK CONSTRAINT [FK_movement_sale_buyout_movement]
GO
ALTER TABLE [dbo].[movement_sale_buyout]  WITH CHECK ADD  CONSTRAINT [FK_movement_sale_buyout_pay_method] FOREIGN KEY([payment_method_id])
REFERENCES [dbo].[pay_method] ([id])
GO
ALTER TABLE [dbo].[movement_sale_buyout] CHECK CONSTRAINT [FK_movement_sale_buyout_pay_method]
GO
ALTER TABLE [dbo].[movement_sale_buyout]  WITH CHECK ADD  CONSTRAINT [FK_movement_sale_buyout_voucher_document] FOREIGN KEY([voucher_document_id])
REFERENCES [dbo].[voucher_document] ([id])
GO
ALTER TABLE [dbo].[movement_sale_buyout] CHECK CONSTRAINT [FK_movement_sale_buyout_voucher_document]
GO
ALTER TABLE [dbo].[operation_accouting_plan]  WITH CHECK ADD  CONSTRAINT [FK_operation_accouting_plan_accounting_plan_detail] FOREIGN KEY([accouting_plan_detail_id])
REFERENCES [dbo].[accounting_plan_detail] ([id])
GO
ALTER TABLE [dbo].[operation_accouting_plan] CHECK CONSTRAINT [FK_operation_accouting_plan_accounting_plan_detail]
GO
ALTER TABLE [dbo].[operation_accouting_plan]  WITH CHECK ADD  CONSTRAINT [FK_operation_accouting_plan_operation_type] FOREIGN KEY([operation_type_id])
REFERENCES [dbo].[operation_type] ([id])
GO
ALTER TABLE [dbo].[operation_accouting_plan] CHECK CONSTRAINT [FK_operation_accouting_plan_operation_type]
GO
ALTER TABLE [dbo].[option_items_auth]  WITH CHECK ADD  CONSTRAINT [FK_option_items_auth_option_auth] FOREIGN KEY([option_auth_id])
REFERENCES [dbo].[option_auth] ([id])
GO
ALTER TABLE [dbo].[option_items_auth] CHECK CONSTRAINT [FK_option_items_auth_option_auth]
GO
ALTER TABLE [dbo].[patient]  WITH CHECK ADD  CONSTRAINT [FK_patient_person] FOREIGN KEY([person_id])
REFERENCES [dbo].[person] ([id])
GO
ALTER TABLE [dbo].[patient] CHECK CONSTRAINT [FK_patient_person]
GO
ALTER TABLE [dbo].[patient_progress_sesion]  WITH CHECK ADD  CONSTRAINT [FK_patient_progress_sesion_employeed] FOREIGN KEY([employeed_id])
REFERENCES [dbo].[employeed] ([id])
GO
ALTER TABLE [dbo].[patient_progress_sesion] CHECK CONSTRAINT [FK_patient_progress_sesion_employeed]
GO
ALTER TABLE [dbo].[patient_progress_sesion]  WITH CHECK ADD  CONSTRAINT [FK_patient_progress_sesion_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient] ([id])
GO
ALTER TABLE [dbo].[patient_progress_sesion] CHECK CONSTRAINT [FK_patient_progress_sesion_patient]
GO
ALTER TABLE [dbo].[patient_progress_sesion]  WITH CHECK ADD  CONSTRAINT [FK_patient_progress_sesion_patient_progress_sesion_detail] FOREIGN KEY([patient_progress_session_detail])
REFERENCES [dbo].[patient_progress_sesion_detail] ([id])
GO
ALTER TABLE [dbo].[patient_progress_sesion] CHECK CONSTRAINT [FK_patient_progress_sesion_patient_progress_sesion_detail]
GO
ALTER TABLE [dbo].[patient_solicitude]  WITH CHECK ADD  CONSTRAINT [FK_patient_solicitude_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient] ([id])
GO
ALTER TABLE [dbo].[patient_solicitude] CHECK CONSTRAINT [FK_patient_solicitude_patient]
GO
ALTER TABLE [dbo].[patient_state_historic]  WITH CHECK ADD  CONSTRAINT [FK_patient_state_historic_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient] ([id])
GO
ALTER TABLE [dbo].[patient_state_historic] CHECK CONSTRAINT [FK_patient_state_historic_patient]
GO
ALTER TABLE [dbo].[payment]  WITH CHECK ADD  CONSTRAINT [FK_payment_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient] ([id])
GO
ALTER TABLE [dbo].[payment] CHECK CONSTRAINT [FK_payment_patient]
GO
ALTER TABLE [dbo].[payment_schedule]  WITH CHECK ADD  CONSTRAINT [FK_payment_schedule_payment] FOREIGN KEY([payment_id])
REFERENCES [dbo].[payment] ([id])
GO
ALTER TABLE [dbo].[payment_schedule] CHECK CONSTRAINT [FK_payment_schedule_payment]
GO
ALTER TABLE [dbo].[payment_schedule_way_to_pay]  WITH CHECK ADD  CONSTRAINT [FK_payment_schedule_way_to_pay_pay_method] FOREIGN KEY([pay_method_id])
REFERENCES [dbo].[pay_method] ([id])
GO
ALTER TABLE [dbo].[payment_schedule_way_to_pay] CHECK CONSTRAINT [FK_payment_schedule_way_to_pay_pay_method]
GO
ALTER TABLE [dbo].[payment_schedule_way_to_pay]  WITH CHECK ADD  CONSTRAINT [FK_payment_schedule_way_to_pay_payment_schedule] FOREIGN KEY([payment_schedule_id])
REFERENCES [dbo].[payment_schedule] ([id])
GO
ALTER TABLE [dbo].[payment_schedule_way_to_pay] CHECK CONSTRAINT [FK_payment_schedule_way_to_pay_payment_schedule]
GO
ALTER TABLE [dbo].[person_cellphone]  WITH CHECK ADD  CONSTRAINT [FK_person_cellphone_person] FOREIGN KEY([person_id])
REFERENCES [dbo].[person] ([id])
GO
ALTER TABLE [dbo].[person_cellphone] CHECK CONSTRAINT [FK_person_cellphone_person]
GO
ALTER TABLE [dbo].[person_document]  WITH CHECK ADD  CONSTRAINT [FK_person_document_document] FOREIGN KEY([document_id])
REFERENCES [dbo].[document] ([id])
GO
ALTER TABLE [dbo].[person_document] CHECK CONSTRAINT [FK_person_document_document]
GO
ALTER TABLE [dbo].[person_document]  WITH CHECK ADD  CONSTRAINT [FK_person_document_person] FOREIGN KEY([person_id])
REFERENCES [dbo].[person] ([id])
GO
ALTER TABLE [dbo].[person_document] CHECK CONSTRAINT [FK_person_document_person]
GO
ALTER TABLE [dbo].[person_email]  WITH CHECK ADD  CONSTRAINT [FK_person_email_person] FOREIGN KEY([person_id])
REFERENCES [dbo].[person] ([id])
GO
ALTER TABLE [dbo].[person_email] CHECK CONSTRAINT [FK_person_email_person]
GO
ALTER TABLE [dbo].[role]  WITH CHECK ADD  CONSTRAINT [FK_role_area] FOREIGN KEY([area_id])
REFERENCES [dbo].[area] ([id])
GO
ALTER TABLE [dbo].[role] CHECK CONSTRAINT [FK_role_area]
GO
ALTER TABLE [dbo].[routes_auth]  WITH CHECK ADD  CONSTRAINT [FK_routes_auth_routes] FOREIGN KEY([routes_id])
REFERENCES [dbo].[routes] ([id])
GO
ALTER TABLE [dbo].[routes_auth] CHECK CONSTRAINT [FK_routes_auth_routes]
GO
/****** Object:  StoredProcedure [dbo].[PA_ACCESS_SYSTEM_POST_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ACCESS_SYSTEM_POST_EMPLOYEED]	--'EJCS', '123456'
	@v_user_access VARCHAR(100)
	, @v_password VARCHAR(100)
AS
BEGIN
	SELECT 
		em.id
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, UPPER(es.description) AS state
		, es.abbreviation AS abbreviation_state
		, UPPER(r.name) AS role
		, pe.profile_picture
		, em.user_name
		, 'E' AS typeUser
		, ISNULL(ec.id, 0) AS employeed_cash_register_id
	FROM employeed em
	INNER JOIN person pe ON pe.id = em.person_id
	INNER JOIN employeed_state es ON es.abbreviation = em.state
	INNER JOIN role r ON r.id = em.role_id
	LEFT JOIN employeed_cash_register ec ON ec.employeed_id = em.id
	WHERE em.user_access = @v_user_access AND em.password = @v_password
	UNION ALL
	SELECT 
		p.id
		, UPPER(pe.names)
		, UPPER(pe.surnames)
		, UPPER(ps.description)
		, ps.abbreviation AS abbreviation_state
		, 'PACIENTE' role 
		, pe.profile_picture AS profile_picture
		, p.user_name
		, 'P' AS typeUser
		, 0 AS employeed_cash_register_id
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	WHERE p.user_access = @v_user_access AND p.password_access = @v_password
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ADD_MENU_AUTH_FATHER_INSERT_PUT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ADD_MENU_AUTH_FATHER_INSERT_PUT]
	@v_employeed_code VARCHAR(4)
	, @v_option_id INT
AS
BEGIN
	
	DECLARE @v_employeed_id INT
	SELECT @v_employeed_id = e.id FROM employeed e WHERE e.user_access = @v_employeed_code

	IF NOT EXISTS(SELECT o.id FROM option_auth o WHERE o.employeed_id = @v_employeed_id AND o.option_id = @v_option_id)
	BEGIN
		INSERT INTO option_auth
		VALUES(@v_option_id, @v_employeed_id, 1, GETDATE(), NULL)
	END
	ELSE
	BEGIN
		UPDATE option_auth
		SET state = 1, modification_date = GETDATE()
		WHERE employeed_id = @v_employeed_id AND option_id = @v_option_id
	END
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ADD_MENU_PERMISO_OPTION_PUT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ADD_MENU_PERMISO_OPTION_PUT]
	@v_option_id INT
	, @v_code_trabajador VARCHAR(4)
	, @v_padre_id INT
AS
BEGIN
	DECLARE @v_employeed_id INT
	DECLARE @v_option_item_id_auth INT
	DECLARE @v_option_item_id INT
	DECLARE @v_option_auth_id INT


	SELECT @v_employeed_id = e.id FROM employeed e WHERE e.user_access = @v_code_trabajador

	SELECT 
		@v_option_item_id_auth = ee.id
	FROM option_items_auth ee INNER JOIN option_auth oo ON oo.id = ee.option_auth_id WHERE oo.employeed_id = @v_employeed_id AND ee.option_items_id = @v_option_id

	IF EXISTS(SELECT ee.id FROM option_items_auth ee WHERE ee.id = @v_option_item_id_auth)
	BEGIN
		UPDATE option_items_auth
		SET state = 1, modification_date = GETDATE()
		WHERE id = @v_option_item_id_auth

		-- Habilitamos la ruta, verificamos primero si existe, si no la creamos
		IF EXISTS(SELECT RA.id FROM [routes] r 
			INNER JOIN option_items o ON o.[to] = r.path
			INNER JOIN routes_auth ra ON ra.routes_id = r.id	
			WHERE o.id = @v_option_id AND ra.employeed_id = @v_employeed_id)
		BEGIN
			UPDATE ra
			SET ra.state = 1, ra.modification_date = GETDATE()
			FROM [routes] r 
			INNER JOIN option_items o ON o.[to] = r.path
			INNER JOIN routes_auth ra ON ra.routes_id = r.id	
			WHERE o.id = @v_option_id AND ra.employeed_id = @v_employeed_id

		END
		ELSE
		BEGIN
			DECLARE @v_route_id_insert INT
			SELECT @v_route_id_insert = rr.id FROM option_items ii INNER JOIN [routes] rr ON RR.path = II.[to] 
			WHERE ii.id = @v_option_id

			INSERT INTO routes_auth
			VALUES(@v_route_id_insert, 1, GETDATE(), NULL, @v_employeed_id)

		END
	END
	ELSE -- Usuario sin opciones, todo nuevo
	BEGIN
		DECLARE @v_option_item_id_auth_final INT = 0
		SELECT @v_option_item_id_auth_final = id FROM option_auth WHERE option_id = @v_padre_id AND employeed_id = @v_employeed_id

		INSERT INTO option_items_auth
		VALUES(@v_option_id, 1, GETDATE(), NULL, @v_option_item_id_auth_final)
		-- Insertamos la ruta relacionada
		IF NOT EXISTS(SELECT A.id FROM option_items a INNER JOIN [routes] b ON b.path = a.[to] INNER JOIN routes_auth c ON c.routes_id = b.id WHERE a.id = @v_option_id AND c.employeed_id = @v_employeed_id)
		BEGIN
			DECLARE @v_route_id INT
			SELECT @v_route_id = b.id FROM option_items a INNER JOIN [routes] b ON b.path = a.[to] WHERE a.id = @v_option_id 
			SELECT @v_route_id, @v_option_id, @v_employeed_id
			INSERT INTO routes_auth 
			VALUES(@v_route_id, 1, GETDATE(), NULL, @v_employeed_id)
			-- Por defecto agregamos la ruta dashboard
			IF NOT EXISTS(SELECT id FROM routes_auth WHERE routes_id = 2 AND employeed_id = @v_employeed_id)
			BEGIN
				INSERT INTO routes_auth 
				VALUES(2, 1, GETDATE(), NULL, @v_employeed_id)
			END
		END
	END
END
 
GO
/****** Object:  StoredProcedure [dbo].[PA_ADD_REMOVE_MENU_PERMISO_OPTION_PUT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ADD_REMOVE_MENU_PERMISO_OPTION_PUT]
	@v_option_item_id INT
	, @v_option_id INT = 0
	, @v_type_trans VARCHAR(1) 
AS
BEGIN
	IF @v_type_trans = 'A' 
	BEGIN
		UPDATE o 
		SET o.modification_date = GETDATE(), o.state = 0
		FROM option_items_auth o
		WHERE o.id = @v_option_item_id
	END
	ELSE IF @v_type_trans = 'I'
	BEGIN
		IF EXISTS(SELECT a.id FROM option_items_auth a WHERE a.id = @v_option_item_id)
		BEGIN
			UPDATE o 
			SET o.modification_date = GETDATE(), o.state = 1
			FROM option_items_auth o
			WHERE o.id = @v_option_item_id 
		END
		ELSE
		BEGIN
			INSERT INTO option_items_auth
			VALUES(1, 1, GETDATE(), NULL, @v_option_id)
		END
	END
END
GO
/****** Object:  StoredProcedure [dbo].[PA_AFP_SURE_GET_AFP_SURE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_AFP_SURE_GET_AFP_SURE]
AS
BEGIN
	SELECT 
		a.id AS value
		, a.name AS label
	FROM afp_sure a
	WHERE a.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_APPOINTMENT_GET_PATIENTSOLICITUDE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PA_APPOINTMENT_GET_PATIENTSOLICITUDE]
AS
BEGIN
	SELECT
		p.id AS id
		, '' AS code
		, UPPER(pe.surnames) AS surnames
		, UPPER(pe.names) AS names
		, (((365 * YEAR(GETDATE())) - (365 * (YEAR(pe.birth_date)))) + (MONTH(GETDATE()) - MONTH(pe.birth_date)) * 30 + (DAY(GETDATE()) - DAY(pe.birth_date))) / 365 AS age
		, UPPER(ps.description) AS state
		, pd.number_document
		, '' AS operator
		, '' AS cellphone
		, '' AS email
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	INNER JOIN person_document pd ON pd.person_id = pe.id AND pd.state = 1 AND pd.is_default = 1
	WHERE p.state = 'D'
END
GO
/****** Object:  StoredProcedure [dbo].[PA_APPOINTMENT_PENDING_GET_PATIENTSOLICITUDE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[PA_APPOINTMENT_PENDING_GET_PATIENTSOLICITUDE]
AS
BEGIN
	SELECT
		p.id AS id
		, ROW_NUMBER() OVER(ORDER BY p.id) AS nro
		, UPPER(pe.surnames) AS surnames
		, UPPER(pe.names) AS names
		, pso.date_attention
		, pso.hour_attention
		, UPPER(peem.names) AS names_employeed
		, UPPER(peem.surnames) AS sur_names_employeed
		, UPPER(r.abbreviation) AS role
		, 'PENDIENTE' AS state
		, UPPER(pss.description) AS reason
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_solicitude pso ON pso.patient_id = p.id
	INNER JOIN employeed em ON em.id = pso.employeed_id
	INNER JOIN person peem ON peem.id = em.person_id
	INNER JOIN role r ON r.id = em.role_id
	INNER JOIN patient_state pss ON pss.abbreviation = p.state
	WHERE p.state = 'A'
END
GO
/****** Object:  StoredProcedure [dbo].[PA_APPOINTMENT_UPDATE_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_APPOINTMENT_UPDATE_PATIENT]
	@v_patient_id INT,
	@v_type AS CHAR(1)
AS
BEGIN
	IF @v_type = 'A'
	BEGIN
		UPDATE patient
		SET state = 'B'
		WHERE id = @v_patient_id

		INSERT INTO patient_state_historic
		VALUES(GETDATE(), @v_patient_id, 'B')
	END
	ELSE IF @v_type = 'R'
	BEGIN
		UPDATE patient
		SET state = 'F'
		WHERE id = @v_patient_id

		INSERT INTO patient_state_historic
		VALUES(GETDATE(), @v_patient_id, 'F')
	END
	ELSE IF @v_type = 'S'
	BEGIN
		UPDATE patient_progress_sesion 
		SET on_hold = 1, modification_date = GETDATE()
		WHERE id = @v_patient_id
	END
END
SELECT * FROM patient_progress_sesion

 

GO
/****** Object:  StoredProcedure [dbo].[PA_APPROVE_CONTRACT_PUT_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_APPROVE_CONTRACT_PUT_EMPLOYEED]
	@v_employeed_id INT
AS
BEGIN
	UPDATE e 
	SET e.contract_approval_date = GETDATE(), state = 'A'
	FROM employeed e
	WHERE e.id = @v_employeed_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_AREA_IN_COMBO_GET_AREA]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PA_AREA_IN_COMBO_GET_AREA]
AS
BEGIN
	SELECT 
		id AS value
		, UPPER(description) AS label
	FROM area
	WHERE state = 1	
END
GO
/****** Object:  StoredProcedure [dbo].[PA_CHARGE_IN_COMBO_GET_ROLE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_CHARGE_IN_COMBO_GET_ROLE]
AS
BEGIN
	SELECT 
		t.id AS value
		, UPPER(t.name) AS label
		, T.salary_to_pay
	FROM role t
	WHERE t.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_CONFIG_GENERAL_GET_CONFIG]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_CONFIG_GENERAL_GET_CONFIG]
AS
BEGIN
	SELECT
		id
		, [key_name] AS key_name_config
		, value
	FROM config
END
GO
/****** Object:  StoredProcedure [dbo].[PA_CONFIG_GENERAL_PUT_CONFIG]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_CONFIG_GENERAL_PUT_CONFIG]
	@v_key_name AS VARCHAR(50)
	, @v_value AS VARCHAR(100)
AS
BEGIN
	UPDATE config
	SET value = @v_value
	WHERE [key_name] = @v_key_name
END
GO
/****** Object:  StoredProcedure [dbo].[PA_CRONOGRAMA_PAGOS_GET_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_CRONOGRAMA_PAGOS_GET_PAYMENT]
@v_patient_id INT
AS
BEGIN
	SELECT 
		pe.names
		, pe.surnames
		, ps.debt_number
		, ps.amount
		, ps.payment_date
		, CASE WHEN ps.state = 1 THEN 'PAGADO' ELSE 'PENDIENTE' END AS state
	FROM payment p
	INNER JOIN patient pa ON pa.id = p.patient_id
	INNER JOIN payment_schedule ps ON ps.payment_id = p.id
	INNER JOIN person pe ON pe.id = pa.person_id
	WHERE pa.id = @v_patient_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_DATA_EMPLOYEED_GET_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_DATA_EMPLOYEED_GET_EMPLOYEED]
AS
BEGIN
	SELECT 
		UPPER(pe.surnames) AS surnames
		, UPPER(pe.names) AS names
		, UPPER(r.abbreviation) AS role
		, UPPER(e.user_access) AS user_access
		, UPPER(es.description) AS state
		, E.admision_date
		, e.user_name
	FROM employeed e
	INNER JOIN person pe ON pe.id = e.person_id
	INNER JOIN role r ON r.id = e.role_id
	INNER JOIN employeed_state es ON es.abbreviation = e.state
	WHERE e.state = 'A' AND e.termination_date IS NULL
END
GO
/****** Object:  StoredProcedure [dbo].[PA_DATA_EMPLOYEED_PENDING_APROVAL_GET_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_DATA_EMPLOYEED_PENDING_APROVAL_GET_EMPLOYEED]
AS
BEGIN
	SELECT e.id AS employeedId,
		CONCAT('[', e.id, '] - ', UPPER(pe.surnames), ', ', UPPER(pe.names)) AS label
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, pe.profile_picture AS profilePicture
		, r.id AS roleId
		, UPPER(r.name) AS role
		, UPPER(ps.description) AS state
		, e.admision_date
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, UPPER(e.user_access) AS user_access
		, CAST(DATEDIFF(DAY, e.admision_date, GETDATE()) / 12 AS DECIMAL(18, 2)) AS vacation_days
		, es.salary
	FROM employeed e
	INNER JOIN person pe ON pe.id = e.person_id
	LEFT JOIN person_document pd ON pd.person_id = pe.id
	INNER JOIN role r ON r.id = e.role_id
	INNER JOIN employeed_state ps ON ps.abbreviation = e.state
	INNER JOIN employeed_salary es ON es.employeed_id = e.id AND es.state = 1
	WHERE e.state = 'P' AND e.termination_date IS NULL
END
GO
/****** Object:  StoredProcedure [dbo].[PA_DATAIL_EMPLOYEED_GET_BY_USERNAME_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_DATAIL_EMPLOYEED_GET_BY_USERNAME_EMPLOYEED] -- 'jdcruzado '
	@v_user_name VARCHAR(50)
AS
BEGIN
	SELECT 
		UPPER(pe.surnames) AS sur_names
		, UPPER(pe.names) AS names
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, ISNULL(pem.email, '-') AS email
		, UPPER(es.description) AS state
		, pe.profile_picture
		, e.user_name
		, pe.birth_date
		, ISNULL(CASE WHEN pe.civil_status = 'C' AND pe.gender = 'M' THEN 'CASADO' 
					  WHEN pe.civil_status = 'C' AND pe.gender = 'F' THEN 'CASADA'
					  WHEN pe.civil_status = 'S' AND pe.gender = 'M' THEN 'SOLTERO'
					  WHEN pe.civil_status = 'S' AND pe.gender = 'F' THEN 'SOLTERA'
				 END, '-') AS civil_status
		, ISNULL(pcc.number_cellphone, '-') AS number_cellphone
		, pe.gender
		, e.id AS employeedId
		, UPPER(r.name) AS role
		, CAST('1' AS BIT) AS isStaff
		, a.id AS area_id
		, UPPER(ISNULL(a.description, '')) AS area
	FROM employeed e
	INNER JOIN person pe ON pe.id = e.person_id
	LEFT JOIN person_email pem ON pem.person_id = pe.id AND pem.state = 1
	LEFT JOIN employeed_state es ON es.abbreviation = e.state
	LEFT JOIN person_cellphone pcc ON pcc.person_id = pe.id AND pcc.is_default = 1 AND pcc.state = 1
	INNER JOIN role r ON r.id = e.role_id
	LEFT JOIN area a ON a.id = r.area_id
	WHERE e.user_name = LTRIM(RTRIM(@v_user_name))
	UNION ALL
	SELECT 
		UPPER(pe.surnames) AS sur_names
		, UPPER(pe.names) AS names
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, ISNULL(pem.email, '-') AS email
		, UPPER(es.description) AS state
		, pe.profile_picture
		, e.user_name
		, pe.birth_date
		, ISNULL(CASE WHEN pe.civil_status = 'C' AND pe.gender = 'M' THEN 'CASADO' 
					  WHEN pe.civil_status = 'C' AND pe.gender = 'F' THEN 'CASADA'
					  WHEN pe.civil_status = 'S' AND pe.gender = 'M' THEN 'SOLTERO'
					  WHEN pe.civil_status = 'S' AND pe.gender = 'F' THEN 'SOLTERA'
				END, '-') AS civil_status		
		, ISNULL(pcc.number_cellphone, '-') AS number_cellphone
		, pe.gender
		, e.id AS employeedId
		, 'USUARIO(A)' AS role
		, CAST('0' AS BIT) AS isStaff
		, 0 AS area_id
		, '' AS area
	FROM patient e
	INNER JOIN person pe ON pe.id = e.person_id
	LEFT JOIN person_email pem ON pem.person_id = pe.id AND pem.state = 1
	LEFT JOIN patient_state es ON es.abbreviation = e.state
	LEFT JOIN person_cellphone pcc ON pcc.person_id = pe.id AND pcc.is_default = 1 AND pcc.state = 1
	WHERE e.user_name = LTRIM(RTRIM(@v_user_name))
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GENERA_CRONOGRAMA_POST_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GENERA_CRONOGRAMA_POST_PAYMENT]
	@v_debt_number INT
	, @v_patient_id INT
	, @v_initial_date DATE
AS
BEGIN
	DECLARE @v_index INT = 1
	DECLARE @v_dia_pago_deuda INT 
	DECLARE @v_sub_total DECIMAL(18, 2)
	DECLARE @v_igv DECIMAL(18, 2)
	DECLARE @v_total DECIMAL(18, 2)
	DECLARE @v_payment_id INT

	SET @v_dia_pago_deuda = (SELECT dbo.fu_return_value_config('dias_pago_deuda'))

	SELECT 
		@v_total = ROUND(CAST((ps.number_sessions * ps.cost_per_unit) AS DECIMAL(18, 2)), 2)
		, @v_igv = (@v_total * 0.18)
		, @v_sub_total = (@v_total - @v_igv)
	FROM patient p 
	INNER JOIN clinic_history c ON c.patient_id = p.id
	INNER JOIN packets_or_unit_sessions ps ON ps.id = c.packet_or_unit_session_id
	WHERE p.id = @v_patient_id

	INSERT INTO payment
	(	patient_id
		, sub_total
		, igv, total
		, created_at
		, state
	)
	VALUES
	(	@v_patient_id
		, @v_sub_total
		, @v_igv
		, @v_total
		, GETDATE()
		, 'A' 
	)

	SET @v_payment_id = @@IDENTITY

	WHILE @v_index <= @v_debt_number
	BEGIN
		DECLARE @v_fecha_pago AS DATE 
		DECLARE @v_amount_pago AS DECIMAL(18, 2)
		DECLARE @v_diff AS DECIMAL(18, 2)

		SET @v_amount_pago = (@v_total / @v_debt_number)
		SET @v_diff = (@v_total - (@v_amount_pago * @v_debt_number))
		IF @v_index = 1 
		BEGIN
			SET @v_fecha_pago = @v_initial_date
			SET @v_amount_pago = @v_amount_pago + @v_diff
		END
		ELSE
		BEGIN
			SET @v_fecha_pago = DATEADD(DAY, @v_dia_pago_deuda, @v_fecha_pago)
		END

		INSERT INTO payment_schedule
		(	debt_number
			, amount
			, payment_date
			, created_at
			, payment_id
		)
		VALUES
		(	@v_index
			, @v_amount_pago
			, @v_fecha_pago
			, GETDATE()
			, @v_payment_id
		)
		SET @v_index = @v_index + 1
	END

	UPDATE patient 
	SET payment_schedule = 1
	WHERE id = @v_patient_id

END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_AREA_IN_SELECT_GET_AREA]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_AREA_IN_SELECT_GET_AREA]
AS
BEGIN
	SELECT 
		a.id AS value
		, a.description AS label
	FROM area a
	WHERE a.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_COUNT_PATIENTS_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_COUNT_PATIENTS_GET_PATIENT]
AS
BEGIN
	-- Primer Analisis Pendiente
	SELECT COUNT(1) AS size, 'PRIMER ANÁLISIS PENDIENTE' AS description, 'warning' AS Type, '/primer-analisis' AS url
	FROM patient p 
	WHERE p.state = 'B' AND flag IS NULL
	UNION ALL
	--SELECT * FROM patient_state
	-- Tratamiento Finalizado
	SELECT COUNT(1) AS size, 'TRATAMIENTO FINALIZADO' AS description, 'success' AS Type, '/pacientes/tratamiento/finalizado' AS url
	FROM patient p  
	WHERE p.state = 'E' AND flag IS NULL
	UNION ALL
	-- En tratamiento
	SELECT COUNT(1) AS size, 'EN TRATAMIENTO' AS description, 'primary' AS Type, '/pacientes/tratamiento/proceso' AS url
	FROM patient p 
	WHERE p.state = 'D' AND flag IS NULL
	UNION ALL
	-- Rechazados
	SELECT COUNT(1) AS size, 'RECHAZADOS' AS description, 'danger' AS Type, '/pacientes/tratamiento/proceso' AS url
	FROM patient p 
	WHERE flag IS NOT NULL
END

 
 
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_DETAIL_SCHEDULE_GET_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PA_GET_DETAIL_SCHEDULE_GET_PAYMENT]
	@v_payment_id INT
AS
BEGIN
	SELECT 
		ps.id,
		ps.payment_id
		, ps.debt_number
		, ps.amount
		, CASE WHEN ISNULL(ps.state, 0) = 0 THEN 'PENDIENTE DE PAGO' ELSE 'PAGADO' END AS state
		, ps.payment_date
	FROM patient p
	INNER JOIN payment pp ON pp.patient_id = p.id
	INNER JOIN payment_schedule ps ON ps.payment_id = pp.id
	INNER JOIN person pe ON pe.id = p.person_id
	WHERE pp.id = @v_payment_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_DETAIL_USERS_MESSAGE_MESSAGE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_DETAIL_USERS_MESSAGE_MESSAGE]
	@v_from_id INT
	, @v_from_type_user CHAR(1)
AS
BEGIN
	SELECT 
		ms.message_content
		, UPPER(CASE WHEN ms.type_user_to = 'E' THEN pem.names ELSE pe.names END) AS names
		, UPPER(CASE WHEN ms.type_user_to = 'E' THEN pem.surnames ELSE pe.surnames END) AS surnames
		, CASE WHEN ms.type_user_to = 'E' THEN pem.profile_picture ELSE pe.profile_picture END AS profile_picture
		, ms.type_user_from
		, ms.type_user_to
		, ms.id
		, ms.to_id
		, ms.from_id
		, CASE WHEN ms.type_user_to = 'E' THEN em.user_name ELSE p.user_name END AS user_name
	FROM patient p 
	LEFT JOIN person pe ON pe.id = p.person_id
	LEFT JOIN (
		SELECT TOP 100 MAX(m.message_content) AS message_content
			, m.to_id
			, m.from_id
			, m.type_user_from
			, m.type_user_to
			, MIN(m.id) AS id
		FROM message m
		WHERE m.state = 1
		GROUP BY m.to_id
			, m.from_id
			, m.type_user_from
			, m.type_user_to
	) MS ON MS.to_id = p.id
	LEFT JOIN employeed em ON em.id = ms.to_id
	LEFT JOIN person pem ON pem.id = em.person_id
	WHERE ms.from_id = @v_from_id AND ms.type_user_from = @v_from_type_user
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_FRECUENCY_GET_FRECUENCY]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_FRECUENCY_GET_FRECUENCY]
AS
BEGIN
	SELECT 
		f.description
		, f.id AS frecuencyId
		, f.abbreviation
		, f.value
		, CASE WHEN f.state = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS state
	FROM frecuency f
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_MESSAGE_DETAIL_MESSAGE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_MESSAGE_DETAIL_MESSAGE]-- 4, 1, 'U'
	@v_to_id INT
	, @v_from_id INT
	, @v_type_user_to CHAR(1)
AS
BEGIN
	--Employeed
	SELECT 
		m.message_content
		, CASE WHEN m.type_user_from = 'E' THEN pe.profile_picture ELSE per.profile_picture END AS profile_picture
		, m.created_at
		, ISNULL(m.seen, 0) AS seen
		, CASE WHEN m.type_user_from = 'E' THEN CAST('1' AS BIT) ELSE '0' END AS is_staff
		, m.from_id
		, m.to_id
		, m.type_user_from
		, m.type_user_to
		, CASE WHEN m.type_user_from = 'E' THEN em.user_name ELSE pa.user_name END AS user_name
	FROM message m
	INNER JOIN employeed em ON em.id = m.from_id  
	INNER JOIN person pe ON pe.id = em.person_id
	INNER JOIN patient pa ON pa.id = m.from_id
	INNER JOIN person per ON per.id = pa.person_id
	WHERE ((m.from_id = @v_from_id AND m.to_id = @v_to_id) OR (m.from_id = @v_to_id AND m.to_id = @v_from_id)) AND m.type_user_to = @v_type_user_to
	AND m.state = 1
	ORDER BY created_at DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_MESSAGE_FOR_ID_USER_GET_MESSAGE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_MESSAGE_FOR_ID_USER_GET_MESSAGE]-- 1
	@v_from_id INT
	, @v_type_user_from CHAR(1)
AS
BEGIN
	SELECT DISTINCT
		ms.message_content
		, UPPER(CASE WHEN ms.type_user_to = 'E' THEN pem.names ELSE pe.names END) AS names
		, UPPER(CASE WHEN ms.type_user_to = 'E' THEN pem.surnames ELSE pe.surnames END) AS surnames
		, CASE WHEN ms.type_user_to = 'E' THEN pem.profile_picture ELSE pe.profile_picture END AS profile_picture
		, ms.type_user_from
		, ms.type_user_to
		, ms.id
		, ms.to_id
		, ms.from_id
		, ms.count_msg
	FROM patient p 
	LEFT JOIN person pe ON pe.id = p.person_id
	LEFT JOIN (
		SELECT MIN(m.message_content) AS message_content
			, m.to_id
			, m.from_id
			, m.type_user_from
			, m.type_user_to
			, MAX(m.id) AS id
			, COUNT(*) AS count_msg
		FROM message m
		WHERE m.state = 1 AND ISNULL(m.seen, 0) = 1
		GROUP BY m.to_id
			, m.from_id
			, m.type_user_from
			, m.type_user_to
	) MS ON MS.to_id = p.id
	LEFT JOIN employeed em ON em.id = ms.to_id
	LEFT JOIN person pem ON pem.id = em.person_id
	WHERE ms.from_id = @v_from_id AND ms.type_user_from = @v_type_user_from
	ORDER BY ms.id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_PAYMENT_GET_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [dbo].[PA_GET_PAYMENT_GET_PAYMENT]
AS
BEGIN
	SELECT
		p.id
		, UPPER(pe.surnames) AS surnames
		, UPPER(pe.names) AS names
		, pou.description AS packet
		, p.total
		, p.igv
		, p.sub_total
		, ISNULL(p.total_cancelled, 0.00) AS total_cancelled
		, ISNULL(p.total, 0.00) - ISNULL(p.total_cancelled, 0.00) AS total_debt
		, UPPER(ps.description) AS state
		, pp.user_name
		, pe.profile_picture
		, PSCHE.debt_number AS debt_number_max
	FROM payment p
	INNER JOIN patient pp ON pp.id = p.patient_id
	INNER JOIN person pe ON pe.id = pp.person_id
	INNER JOIN clinic_history pss ON pss.patient_id = pp.id
	INNER JOIN packets_or_unit_sessions pou ON pou.id = pss.packet_or_unit_session_id
	INNER JOIN payment_state ps ON ps.abbreviation = p.state
	INNER JOIN (
		SELECT MAX(ps.debt_number) AS debt_number, PS.payment_id
		FROM payment_schedule ps
		GROUP BY ps.payment_id
	) AS PSCHE ON PSCHE.payment_id = p.id
	ORDER BY p.created_at DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_REPORT_MENSUAL_CATEGORY_TTO]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_REPORT_MENSUAL_CATEGORY_TTO]
AS
BEGIN
	SELECT 
		SUM(CASE WHEN MONTH(psh.created_at) = 1 THEN 1 ELSE 0 END) AS [1]
		, SUM(CASE WHEN MONTH(psh.created_at) = 2 THEN 1 ELSE 0 END) AS [2]
		, SUM(CASE WHEN MONTH(psh.created_at) = 3 THEN 1 ELSE 0 END) AS [3]
		, SUM(CASE WHEN MONTH(psh.created_at) = 4 THEN 1 ELSE 0 END) AS [4]
		, SUM(CASE WHEN MONTH(psh.created_at) = 5 THEN 1 ELSE 0 END) AS [5]
		, SUM(CASE WHEN MONTH(psh.created_at) = 6 THEN 1 ELSE 0 END) AS [6]
		, SUM(CASE WHEN MONTH(psh.created_at) = 7 THEN 1 ELSE 0 END) AS [7]
		, SUM(CASE WHEN MONTH(psh.created_at) = 8 THEN 1 ELSE 0 END) AS [8]
		, SUM(CASE WHEN MONTH(psh.created_at) = 9 THEN 1 ELSE 0 END) AS [9]
		, SUM(CASE WHEN MONTH(psh.created_at) = 10 THEN 1 ELSE 0 END) AS [10]
		, SUM(CASE WHEN MONTH(psh.created_at) = 11 THEN 1 ELSE 0 END) AS [11]
		, SUM(CASE WHEN MONTH(psh.created_at) = 12 THEN 1 ELSE 0 END) AS [12]
	FROM patient_state_historic psh
	INNER JOIN patient p ON p.id = psh.patient_id 
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state pss ON psh.state = pss.abbreviation
	WHERE psh.state IN('C')
	GROUP BY psh.state
	UNION ALL
	SELECT 
		SUM(CASE WHEN MONTH(psh.created_at) = 1 THEN 1 ELSE 0 END) AS [1]
		, SUM(CASE WHEN MONTH(psh.created_at) = 2 THEN 1 ELSE 0 END) AS [2]
		, SUM(CASE WHEN MONTH(psh.created_at) = 3 THEN 1 ELSE 0 END) AS [3]
		, SUM(CASE WHEN MONTH(psh.created_at) = 4 THEN 1 ELSE 0 END) AS [4]
		, SUM(CASE WHEN MONTH(psh.created_at) = 5 THEN 1 ELSE 0 END) AS [5]
		, SUM(CASE WHEN MONTH(psh.created_at) = 6 THEN 1 ELSE 0 END) AS [6]
		, SUM(CASE WHEN MONTH(psh.created_at) = 7 THEN 1 ELSE 0 END) AS [7]
		, SUM(CASE WHEN MONTH(psh.created_at) = 8 THEN 1 ELSE 0 END) AS [8]
		, SUM(CASE WHEN MONTH(psh.created_at) = 9 THEN 1 ELSE 0 END) AS [9]
		, SUM(CASE WHEN MONTH(psh.created_at) = 10 THEN 1 ELSE 0 END) AS [10]
		, SUM(CASE WHEN MONTH(psh.created_at) = 11 THEN 1 ELSE 0 END) AS [11]
		, SUM(CASE WHEN MONTH(psh.created_at) = 12 THEN 1 ELSE 0 END) AS [12]
	FROM patient_state_historic psh
	INNER JOIN patient p ON p.id = psh.patient_id 
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state pss ON psh.state = pss.abbreviation
	WHERE psh.state IN('D')
	GROUP BY psh.state
	UNION ALL
	SELECT 
		SUM(CASE WHEN MONTH(psh.created_at) = 1 THEN 1 ELSE 0 END) AS [1]
		, SUM(CASE WHEN MONTH(psh.created_at) = 2 THEN 1 ELSE 0 END) AS [2]
		, SUM(CASE WHEN MONTH(psh.created_at) = 3 THEN 1 ELSE 0 END) AS [3]
		, SUM(CASE WHEN MONTH(psh.created_at) = 4 THEN 1 ELSE 0 END) AS [4]
		, SUM(CASE WHEN MONTH(psh.created_at) = 5 THEN 1 ELSE 0 END) AS [5]
		, SUM(CASE WHEN MONTH(psh.created_at) = 6 THEN 1 ELSE 0 END) AS [6]
		, SUM(CASE WHEN MONTH(psh.created_at) = 7 THEN 1 ELSE 0 END) AS [7]
		, SUM(CASE WHEN MONTH(psh.created_at) = 8 THEN 1 ELSE 0 END) AS [8]
		, SUM(CASE WHEN MONTH(psh.created_at) = 9 THEN 1 ELSE 0 END) AS [9]
		, SUM(CASE WHEN MONTH(psh.created_at) = 10 THEN 1 ELSE 0 END) AS [10]
		, SUM(CASE WHEN MONTH(psh.created_at) = 11 THEN 1 ELSE 0 END) AS [11]
		, SUM(CASE WHEN MONTH(psh.created_at) = 12 THEN 1 ELSE 0 END) AS [12]
	FROM patient_state_historic psh
	INNER JOIN patient p ON p.id = psh.patient_id 
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state pss ON psh.state = pss.abbreviation
	WHERE psh.state IN('E')
	GROUP BY psh.state
END
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_ROLE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_ROLE]
AS
BEGIN
	SELECT 
		r.id
		, r.name
		, r.abbreviation
		, r.salary_to_pay
		, CASE WHEN r.state = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END as state_decription
		, r.state
		, a.id AS area_id
		, ISNULL(a.description, '') AS area
	FROM role r
	LEFT JOIN area a ON a.id = r.area_id
	ORDER BY salary_to_pay DESC

END

 
GO
/****** Object:  StoredProcedure [dbo].[PA_GET_SOLICITUD_IN_DRAFT_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_GET_SOLICITUD_IN_DRAFT_GET_PATIENT]
AS
BEGIN
	SELECT 
		pe.surnames
		, pe.names
		, pe.birth_date
		, pd.number_document
		, ISNULL(d.id, 0) AS document_id
		, pe.gender
		, ISNULL(em.id, 0) AS employeed_id
		, ps.hour_attention
		, ps.date_attention
		, ISNULL(peem.surnames, '') AS surnames_employeed
		, ISNULL(peem.names, '') AS names_employeed
		, ISNULL(pc.number_cellphone, '') AS number_cellphone
		, ISNULL(pemail.email, '') AS email
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_solicitude ps ON ps.patient_id = p.id
	LEFT JOIN person_document pd ON pd.person_id = pe.id
	LEFT JOIN document d ON d.id = pd.document_id
	LEFT JOIN employeed em ON em.id = ps.employeed_id
	LEFT JOIN person peem ON peem.id = em.person_id
	LEFT JOIN person_cellphone pc ON pc.person_id = pe.id
	LEFT JOIN person_email pemail ON pemail.person_id = pe.id
	WHERE p.save_to_draft = 1 AND p.state = 'A' AND flag IS NULL
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ME_GET_OPTION]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ME_GET_OPTION]
AS
BEGIN
	SELECT 
	o.id
		, o.component
		, o.name
		, o.icon
		, o.state
		--, oi.name AS name_item
		--, oi.option_id
	FROM [option] o
	--INNER JOIN option_items oi ON oi.option_id = o.id
	WHERE o.state = 1  
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ME_GET_OPTION_ITEMS]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ME_GET_OPTION_ITEMS]  --3
AS
BEGIN
	SELECT 
		id
		, component
		, name
		, state
		, [to]
		, option_id
	FROM [option_items]
	--WHERE option_id = @v_option_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_MENU_GET_OPTION]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[PA_MENU_GET_OPTION] -- 2
@v_employeed_id INT
AS
BEGIN
	SELECT
		au.id
		, o.component
		, o.name
		, ISNULL(o.icon, '') AS icon
	FROM [option] o
	INNER JOIN option_auth au ON au.option_id = o.id
	WHERE au.state = 1 AND au.employeed_id = @v_employeed_id  
END
GO
/****** Object:  StoredProcedure [dbo].[PA_MENU_GET_OPTION_ITEMS]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[PA_MENU_GET_OPTION_ITEMS] 
	@v_option_id INT
	, @v_employeed_id INT
AS
BEGIN
	SELECT
		o.id
		, o.component
		, o.name
		, o.[to] AS [to]
	FROM [option_items] o
	INNER JOIN option_items_auth au ON au.option_items_id = o.id
	INNER JOIN option_auth oo ON oo.id = au.option_auth_id
	WHERE au.state = 1 AND oo.id = @v_option_id AND oo.employeed_id = @v_employeed_id
	ORDER BY o.orden ASC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_MENU_HIJO_GET_OPTION_BY_CODE_EMP]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_MENU_HIJO_GET_OPTION_BY_CODE_EMP]
	@v_code_employeed VARCHAR(4)
AS
BEGIN
	DECLARE @v_employeed_id INT
	SELECT DISTINCT @v_employeed_id = e.id FROM employeed e WHERE e.user_access = @v_code_employeed

	SELECT
		au.id
		, o.component
		, o.name
		, au.state
		, o.[to] AS [to]
		, au.option_auth_id
	FROM [option_items] o
	INNER JOIN option_items_auth au ON au.option_items_id = o.id
	INNER JOIN option_auth oo ON oo.id = au.option_auth_id
	WHERE au.state = 1 AND oo.employeed_id = @v_employeed_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_MENU_PADRE_GET_OPTION_BY_CODE_EMP]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_MENU_PADRE_GET_OPTION_BY_CODE_EMP]
	@v_code_employeed VARCHAR(4)
AS
BEGIN
	DECLARE @v_employeed_id INT
	SELECT DISTINCT @v_employeed_id = e.id FROM employeed e WHERE e.user_access = @v_code_employeed
	
	SELECT
		au.id
		, o.component
		, o.name
		, ISNULL(o.icon, '') AS icon
	FROM [option] o
	INNER JOIN option_auth au ON au.option_id = o.id
	WHERE au.state = 1 AND au.employeed_id = @v_employeed_id 
END
GO
/****** Object:  StoredProcedure [dbo].[PA_MODALITY_IN_COMBO_GET_MODALITY_CONTRACT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_MODALITY_IN_COMBO_GET_MODALITY_CONTRACT]
AS
BEGIN
	SELECT 
		t.id AS value
		, CONCAT(t.name, ' - [', t.abbreviation, ']') AS label
	FROM modality_contract t
	WHERE t.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PACIENTES_PRIMER_ANALISIS_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PACIENTES_PRIMER_ANALISIS_GET_PATIENT]
AS
BEGIN
	SELECT 
		p.id
		, pe.names AS names_patient
		, pe.surnames AS surnames_patient
		, ps.hour_attention
		, ps.date_attention
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, pe.birth_date
		, pd.number_document
		, pe.profile_picture
		, UPPER(pss.description) AS state
		, cc.frecuency_id
		, UPPER(pem.names) AS names_employeed
		, UPPER(pem.surnames) AS surnames_employeed
		, cc.packet_or_unit_session_id AS packet_id
		, pu.cost_per_unit
		, pu.number_sessions
		, pu.maximum_fees_to_pay
		, pu.abbreviation
		, ISNULL(p.payment_schedule, 0) AS payment_schedule
		, ISNULL(MIN(PAYS.payment_date), '1900-01-01') AS initial_date
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_solicitude ps ON ps.patient_id = p.id
	INNER JOIN employeed em ON em.id = ps.employeed_id
	INNER JOIN person pem ON pem.id = em.person_id
	INNER JOIN clinic_history cc ON cc.patient_id = p.id
	INNER JOIN packets_or_unit_sessions pu ON pu.id = cc.packet_or_unit_session_id
	INNER JOIN frecuency f ON f.id = cc.frecuency_id 
	LEFT JOIN person_document pd ON pd.person_id = pe.id  AND pd.is_default = 1 AND pd.state = 1
	LEFT JOIN person_cellphone pc ON pc.person_id = pe.id AND pc.is_default = 1 AND pc.state = 1
	INNER JOIN patient_state pss ON pss.abbreviation = p.state
	LEFT JOIN payment pay ON pay.patient_id = p.id
	LEFT JOIN payment_schedule pays ON pays.payment_id = pay.id
	WHERE p.state = 'C' 
	GROUP BY
		p.id
		, pe.names 
		, pe.surnames  
		, ps.hour_attention
		, ps.date_attention
		, dbo.fu_return_current_age(pe.birth_date) 
		, pe.birth_date
		, pd.number_document
		, pe.profile_picture
		, UPPER(pss.description)  
		, cc.frecuency_id
		, UPPER(pem.names) 
		, UPPER(pem.surnames)  
		, cc.packet_or_unit_session_id 
		, pu.cost_per_unit
		, pu.number_sessions
		, pu.maximum_fees_to_pay
		, pu.abbreviation
		, p.payment_schedule
	ORDER BY p.id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PATIENT_FINISHED_TREATMENT_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PATIENT_FINISHED_TREATMENT_GET_PATIENT]
AS
BEGIN
	SELECT 
		p.id
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, pe.profile_picture
		, CASE WHEN pe.gender = 'F' THEN 'FEMENINO' ELSE 'MASCULINO' END AS gender
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, UPPER(ps.description) AS state
		, pos.description AS packet_desc
		, UPPER(f.description) AS frecuency_desc
		, p.user_name AS user_name_patient
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	INNER JOIN clinic_history cc ON cc.patient_id = p.id
	INNER JOIN packets_or_unit_sessions pos ON pos.id = cc.packet_or_unit_session_id
	INNER JOIN frecuency f ON f.id = cc.frecuency_id
	WHERE p.state = 'E'
	ORDER BY p.id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PATIENT_IN_ATTENTION_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PATIENT_IN_ATTENTION_GET_PATIENT]
AS
BEGIN
	SELECT TOP 5
		UPPER(pe.surnames) AS surnames
		, UPPER(pe.names) AS names
		, pe.profile_picture
		, UPPER(ps.description) AS reason
		, PD.session_date
		, PD.session_hour
		, UPPER(pem.names) AS names_employeed
		, UPPER(pem.surnames) AS surnames_employeed
		, pem.profile_picture AS profile_picture_employeed
		, UPPER(r.abbreviation) AS role
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	INNER JOIN (
		SELECT pps.session_date AS session_date
			, PPS.patient_id
			, pps.id
			, PPS.employeed_id
			, pps.session_hour
		FROM patient_progress_sesion pps
		WHERE pps.on_hold = 1 AND ISNULL(pps.attended, 0) = 0 AND pps.state = 'A'
		AND pps.session_date = CAST(GETDATE() AS DATE)
	) AS PD ON PD.patient_id = p.id
	INNER JOIN employeed em ON em.id = pd.employeed_id
	INNER JOIN person pem ON pem.id = em.person_id
	INNER JOIN role r ON r.id = em.role_id
	WHERE p.state = 'D' AND ISNULL(save_to_draft, 0) = 0 AND p.flag IS NULL
	ORDER BY pd.session_date ASC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PATIENT_IN_TREATMENT_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PATIENT_IN_TREATMENT_GET_PATIENT]
AS
BEGIN
	SELECT 
		p.id
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, pe.profile_picture
		, CASE WHEN pe.gender = 'F' THEN 'FEMENINO' ELSE 'MASCULINO' END AS gender
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, UPPER(ps.description) AS state
		, pos.description AS packet_desc
		, UPPER(f.description) AS frecuency_desc
		, pps.employeed_id
		, p.user_name
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	INNER JOIN clinic_history cc ON cc.patient_id = p.id
	INNER JOIN packets_or_unit_sessions pos ON pos.id = cc.packet_or_unit_session_id
	INNER JOIN frecuency f ON f.id = cc.frecuency_id
	INNER JOIN patient_solicitude pps ON pps.patient_id = p.id
	WHERE p.state = 'D'
	ORDER BY p.id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PATIENT_IN_WAITING_GET_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PATIENT_IN_WAITING_GET_PATIENT]
AS
BEGIN
	SELECT TOP 5
		pe.surnames
		, pe.names
		, pe.profile_picture
		, UPPER(ps.description) AS reason
		, pd.date_attention
		, pd.hour_attention
		, UPPER(pem.names) AS names_employeed
		, UPPER(pem.surnames) AS surnames_employeed
		, pem.profile_picture AS profile_picture_employeed
		, UPPER(r.abbreviation) AS role
		, ISNULL(em.user_name, '-') AS user_name
		, ISNULL(p.user_name, '-') AS user_name_patient
		, ISNULL(pc.number_cellphone, '-') AS number_cellphone
		, ISNULL(pce.number_cellphone, '-') AS number_cellphone_em
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state ps ON ps.abbreviation = p.state
	INNER JOIN patient_solicitude pd ON pd.patient_id = p.id
	INNER JOIN employeed em ON em.id = pd.employeed_id
	INNER JOIN person pem ON pem.id = em.person_id
	INNER JOIN role r ON r.id = em.role_id
	LEFT JOIN person_cellphone pc ON pc.person_id = pe.id AND pc.is_default = 1 AND pc.state = 1
	LEFT JOIN person_cellphone pce ON pce.person_id = pem.id AND pc.is_default = 1 AND pc.state = 1
	WHERE p.state = 'A' AND ISNULL(save_to_draft, 0) = 0 AND p.flag IS NULL
	ORDER BY pd.date_attention ASC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PATIENT_PROGRESS_DETAIL_GEBYID_PATIENT_PROGRESS_SESION]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PATIENT_PROGRESS_DETAIL_GEBYID_PATIENT_PROGRESS_SESION]-- 8
@v_patient_progress_id INT
AS
BEGIN
	SELECT 
		ps.id
		, ps.session_number
		, ISNULL(ps.attended, 0) AS attended
		, ps.session_hour
		, dbo.fu_return_system_hour(ps.session_hour) AS system_hour
		, ps.session_date
		, UPPER(pepa.names) AS name_patient
		, UPPER(pepa.surnames) AS surnames_patient
		, pepa.profile_picture
		, ISNULL(em.id, 0) AS employeed_id
		, ISNULL(UPPER(pem.names), '-') AS names_employeed
		, ISNULL(UPPER(pem.surnames), '-') AS surnames_employeed
		, ISNULL(r.name, '-') AS role_employeed
		, em.user_name
		, p.user_name AS user_name_patient
		, ISNULL(ps.on_hold, 0) AS on_hold
	FROM patient_progress_sesion ps
	INNER JOIN patient p ON p.id = ps.patient_id
	LEFT JOIN employeed em ON em.id = ps.employeed_id
	INNER JOIN person pepa ON pepa.id = p.person_id
	LEFT JOIN person pem ON pem.id = em.person_id
	LEFT JOIN role r ON r.id = em.role_id
	WHERE ps.id = @v_patient_progress_id    
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PAY_DEBT_PUT_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PAY_DEBT_PUT_PAYMENT]
	@v_payment_schedule_id INT
	, @v_payment_debt INT
	, @v_payment_user VARCHAR(4)
	, @v_concepto_pago VARCHAR(50)
	, @v_pay_method_id INT
	, @v_cash DECIMAL(18, 2)
	, @v_monetary_exchange DECIMAL(18, 2)
	, @v_type_document_vou AS INT = 0
	, @v_is_new_customer AS BIT = 0
AS
BEGIN
	DECLARE @v_payment_id INT
	DECLARE @v_amount DECIMAL(18, 2)  
	DECLARE @payment_schedule_way_to_pay INT
	DECLARE @v_description_ope VARCHAR(200)
	DECLARE @v_movement_id INT

	SELECT @v_payment_id = s.payment_id, @v_amount = s.amount FROM payment_schedule s WHERE s.id = @v_payment_schedule_id AND s.debt_number = @v_payment_debt

	UPDATE ps 
	SET ps.payment_date_canceled = GETDATE()
		, ps.state = 1
		, ps.user_payment = @v_payment_user
	FROM payment_schedule ps
	WHERE id = @v_payment_schedule_id AND debt_number = @v_payment_debt

	UPDATE p
	SET p.total_cancelled = ISNULL(p.total_cancelled, 0.00) + @v_amount
		, p.modification_date = GETDATE()
	FROM payment p
	WHERE p.id = @v_payment_id

	UPDATE p
	SET p.total_debt = ISNULL(p.total, 0.00) - ISNULL(p.total_cancelled, 0.00)
	FROM payment p
	WHERE p.id = @v_payment_id

	UPDATE p 
	SET p.state = 'C'
	FROM payment p WHERE p.id = @v_payment_id AND ISNULL(p.total_debt, 0) = 0

	INSERT INTO payment_schedule_way_to_pay
	(
		payment_schedule_id
		, pay_method_id
		, concept
		, created_at
		, state
		, cash
		, monetary_exchange
	)
	VALUES
	(
		@v_payment_schedule_id
		, @v_pay_method_id
		, @v_concepto_pago
		, GETDATE()
		, 1
		, @v_cash
		, @v_monetary_exchange
	)
	SET @payment_schedule_way_to_pay = @@IDENTITY

	SELECT @v_description_ope = a.name FROM operation_type a WHERE a.operation_code = '100000'
	INSERT INTO movement
	(
		number_movement
		, description
		, code_movement
		, flag
		, created_at
	)
	VALUES
	(
		''
		, @v_description_ope
		, '100000'
		, 0
		, GETDATE()
	)
	SET @v_movement_id = @@IDENTITY

	INSERT INTO movement_pay
	(
		payment_sche_way_id
		, state
		, movement_id
	)
	VALUES
	(
		@payment_schedule_way_to_pay
		, 1
		, @v_movement_id
	)
	--Insertamos el pago de la cuota como una venta nueva (ingreso)
	--Agregamos cliente
	DECLARE @v_customer_id_insert_id_pay_cuota INT

	IF @v_is_new_customer = 0
	BEGIN
		DECLARE @v_person_id_pay_cuota INT

		SELECT 
			@v_person_id_pay_cuota = pe.id
		FROM patient pp
		INNER JOIN person pe ON pe.id = pp.person_id
		INNER JOIN payment pa ON pa.patient_id = pp.id
		WHERE pa.id = @v_payment_id

		INSERT INTO customer
		VALUES(@v_person_id_pay_cuota, 'P', GETDATE(), NULL, 1)
		SET @v_customer_id_insert_id_pay_cuota = @@IDENTITY
	END
	INSERT INTO movement_sale_buyout
	(
		movement_id
		, sub_total
		, igv
		, total
		, discount
		, turned
		, payment_method_id
		, serie
		, number
		, type_transaction
		, code_employeed
		, customer_id
		, state
		, created_at
		, modification_date
		, voucher_document_id
	)
	VALUES
	(
		@v_movement_id
		, CAST(@v_amount - @v_amount * 0.18 AS DECIMAL(18, 2))
		, CAST(@v_amount * 0.18 AS DECIMAL(18, 2))
		, @v_amount
		, 0.00
		, @v_monetary_exchange
		, @v_pay_method_id
		, dbo.fu_return_serie_or_number(@v_type_document_vou, 'S', 'V') 
		, dbo.fu_return_serie_or_number(@v_type_document_vou, 'N', 'V') 
		, 'V'
		, 'SIST'
		, @v_customer_id_insert_id_pay_cuota
		, 1
		, GETDATE()
		, NULL
		, @v_type_document_vou
	)

	--Emitimos el comprobante de pago
	IF EXISTS(SELECT p.id FROM payment p WHERE p.id = @v_payment_id AND ISNULL(p.total_debt, 0) = 0)
	BEGIN
		DECLARE @v_movement_id_insert_sale INT
		DECLARE @v_description_ope_insert_sale AS VARCHAR(50)
		DECLARE @v_operation_code AS VARCHAR(20) = '100001'
		SET @v_operation_code = '100001'
		SET @v_description_ope_insert_sale = (SELECT a.name FROM operation_type a WHERE a.operation_code = @v_operation_code)
		INSERT INTO movement
		(
			description
			, code_movement
			, flag
			, created_at
		)
		VALUES
		(	
			@v_description_ope_insert_sale
			, @v_operation_code
			, 0
			, GETDATE()
		)
		SET @v_movement_id_insert_sale = @@IDENTITY
		--Agregamos cliente
		DECLARE @v_customer_id_insert_id INT

		IF @v_is_new_customer = 0
		BEGIN
			DECLARE @v_person_id INT

			SELECT 
				@v_person_id = pe.id
			FROM patient pp
			INNER JOIN person pe ON pe.id = pp.person_id
			INNER JOIN payment pa ON pa.patient_id = pp.id
			WHERE pa.id = @v_payment_id

			INSERT INTO customer
			VALUES(@v_person_id, 'P', GETDATE(), NULL, 1)
			SET @v_customer_id_insert_id = @@IDENTITY
		END
		INSERT INTO movement_sale_buyout
		(
			movement_id
			, sub_total
			, igv
			, total
			, discount
			, turned
			, payment_method_id
			, serie
			, number
			, type_transaction
			, code_employeed
			, customer_id
			, state
			, created_at
			, modification_date
			, voucher_document_id
		)
		SELECT 
			@v_movement_id_insert_sale
			, p.sub_total
			, p.igv
			, p.total
			, 0.00 AS discount
			, 0.00 AS turned
			, @v_pay_method_id
			, dbo.fu_return_serie_or_number(@v_type_document_vou, 'S', 'V') AS serie
			, dbo.fu_return_serie_or_number(@v_type_document_vou, 'N', 'V') AS number
			, 'V' AS type_transaction
			, 'SIST' code_employeed
			, @v_customer_id_insert_id
			, 1
			, GETDATE()
			, NULL
			, @v_type_document_vou
		FROM payment p WHERE p.id = @v_payment_id
	END
END



GO
/****** Object:  StoredProcedure [dbo].[PA_PAY_DETAIL_GETBYID_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PAY_DETAIL_GETBYID_PAYMENT] --4
@v_patient_id INT
AS
BEGIN
	SELECT 
		ps.id
		, ps.debt_number
		, ps.amount
		, ps.payment_date
		, pse.description AS packet_description
		, ff.description AS frecuency_description
		, UPPER(pst.description) AS state
		, pe.surnames
		, pe.names
		, p.id AS payment_id
	FROM payment p
	INNER JOIN payment_schedule ps ON ps.payment_id = p.id
	INNER JOIN patient pa ON pa.id = p.patient_id
	INNER JOIN clinic_history cc ON cc.patient_id = pa.id
	INNER JOIN packets_or_unit_sessions pse ON pse.id = cc.packet_or_unit_session_id
	INNER JOIN frecuency ff ON ff.id = cc.frecuency_id
	INNER JOIN payment_state pst ON pst.abbreviation = p.state
	INNER JOIN person pe ON pe.id = pa.person_id
	WHERE pa.id = @v_patient_id AND pa.state IN('D', 'E')
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PAY_DETAIL_HISTORY_GETBYID_PAYMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PA_PAY_DETAIL_HISTORY_GETBYID_PAYMENT]
	@v_payment_id INT
AS
BEGIN
	SELECT 
		s.payment_date_canceled
		, s.debt_number
		, s.amount
		, s.user_payment
	FROM payment_schedule s
	WHERE s.id = @v_payment_id AND s.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PAYMETHODS_GET_PAY_METHOD]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PAYMETHODS_GET_PAY_METHOD]
AS
BEGIN
	SELECT 
		p.id AS value
		, p.abbreviation AS label
		, p.description
		, ISNULL(p.have_concept, 0) AS have_concept
	FROM pay_method p
	WHERE p.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PERCENTAGE_TREATMENT_GETBYID_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PERCENTAGE_TREATMENT_GETBYID_PATIENT]  -- 4
	@v_patient_id INT
AS
BEGIN
	SELECT DISTINCT
		pe.names
		, pe.surnames
		, pe.profile_picture
		, 0 AS percentage 
		, MIN(ps.session_date) AS date_initial
		, MAX(ps.session_date) AS date_finished
		, 0 AS number_session
		, p.id

		INTO #tmp_patient
	FROM patient p
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_progress_sesion ps ON ps.patient_id = p.id
	WHERE p.payment_schedule = 1 AND p.id = @v_patient_id
	GROUP BY
		pe.names
		, pe.surnames
		, pe.profile_picture
		, p.id

	SELECT ((CASE WHEN ps.attended = 1 THEN SUM(1) END) * 100 / pp.number_sessions) AS percentage, pp.number_sessions, t.id INTO #tmp_percentage
	FROM #tmp_patient t
	LEFT JOIN patient_progress_sesion ps ON ps.patient_id = t.id
	INNER JOIN clinic_history cc ON cc.patient_id = t.id
	INNER JOIN packets_or_unit_sessions pp ON pp.id = cc.packet_or_unit_session_id
	GROUP BY 
		ps.attended
		, t.number_session
		, pp.number_sessions
		, t.id
	HAVING CASE WHEN ps.attended = 1 THEN COUNT(1) ELSE 0 END > 0

	SELECT 
		p.names
		, p.surnames
		, p.profile_picture
		, t.percentage
		, p.date_initial
		, p.date_finished
		, t.number_sessions
	FROM #tmp_percentage t
	INNER JOIN #tmp_patient p ON p.id = t.id
	WHERE t.id = @v_patient_id

	DROP TABLE #tmp_patient
	DROP TABLE #tmp_percentage
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PROGRESS_SESION_POST_PATIENT_PROGRESS_SESION_DETAIL]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PROGRESS_SESION_POST_PATIENT_PROGRESS_SESION_DETAIL]
	@v_patient_description VARCHAR(4000)
	, @v_patient_recommendation VARCHAR(4000)
	, @v_patient_progress_id INT
	, @v_time AS TIME
AS
BEGIN

	DECLARE @v_patient_progress_sesion_detail_id INT = 0
	DECLARE @v_number_sessions INT = 0
	DECLARE @v_number_sessions_ingresada INT = 0
	DECLARE @v_patient_id INT = 0
	DECLARE @v_permite_registro_directo BIT = 0
	SET @v_permite_registro_directo = (SELECT dbo.fu_return_value_config('permite_registrar_directo'))
	SELECT 
		@v_patient_id = patient_id
		, @v_number_sessions_ingresada = pp.session_number
	FROM patient_progress_sesion pp WHERE pp.id = @v_patient_progress_id

	SELECT @v_number_sessions = ps.number_sessions
	FROM clinic_history cc
	INNER JOIN packets_or_unit_sessions ps ON ps.id = cc.packet_or_unit_session_id
	WHERE cc.patient_id = @v_patient_id

	INSERT INTO patient_progress_sesion_detail
	(	
		recommendation
		, description
		, created_at
		, state
		, time_demoration
	)
	VALUES
	(
		@v_patient_recommendation
		, @v_patient_description
		, GETDATE()
		, 1
		, @v_time
	)
	SET @v_patient_progress_sesion_detail_id = @@IDENTITY

	UPDATE patient_progress_sesion
	SET attended = 1
		, patient_progress_session_detail = @v_patient_progress_sesion_detail_id
		, modification_date = GETDATE()
		, state = 'C'
	WHERE id = @v_patient_progress_id

	IF @v_permite_registro_directo = 1
	BEGIN
		UPDATE patient_progress_sesion
		SET on_hold = 1, modification_date = GETDATE()
		WHERE id = @v_patient_progress_id
	END

	IF @v_number_sessions_ingresada = @v_number_sessions
	BEGIN
		UPDATE patient
		SET state = 'E'
		WHERE id = @v_patient_id

		INSERT INTO patient_state_historic
		(	created_at
			, patient_id
			, state
		)
		VALUES
		(
			GETDATE()
			, @v_patient_id
			, 'E'
		)
	END
END
GO
/****** Object:  StoredProcedure [dbo].[PA_PUT_DISABLED_ENABLED_ROLE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PUT_DISABLED_ENABLED_ROLE]
	@v_role_id INT
	, @v_type INT
AS
BEGIN
	UPDATE role
	SET state = (CASE WHEN @v_type = 1 THEN 0 ELSE 1 END), modification_date = GETDATE()
	WHERE id = @v_role_id

END
GO
/****** Object:  StoredProcedure [dbo].[PA_PUT_ROLE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_PUT_ROLE]
	@v_name VARCHAR(200)
	, @v_abbreviation VARCHAR(200)
	, @v_salary DECIMAL(18, 2)
	, @v_area_id INT
	, @v_role_id INT
AS
BEGIN

	UPDATE role 
	SET name = @v_name
		, abbreviation = @v_abbreviation
		, salary_to_pay = @v_salary
		, area_id = @v_area_id
		, modification_date = GETDATE()
	WHERE id = @v_role_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_ATTENTION_GET_PACKETS_OR_UNIT_SESSIONES]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_ATTENTION_GET_PACKETS_OR_UNIT_SESSIONES]
AS
BEGIN
	SELECT 
		s.id
		, s.description
		, s.created_at
		, s.number_sessions
		, s.cost_per_unit 
		, s.abbreviation
		, s.maximum_fees_to_pay
		, CASE WHEN s.state = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS state
		, s.state AS state_value
	FROM packets_or_unit_sessions s
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_EMPLOYEED_POST_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_EMPLOYEED_POST_EMPLOYEED]
	-- Persona
	@v_surnames VARCHAR(300)
	, @v_names VARCHAR(200)
	, @v_birthdate DATE
	, @v_type_document_id INT
	, @v_nro_document VARCHAR(20)
	, @v_gender CHAR(1)
	, @v_cellphone VARCHAR(15)
	, @v_email VARCHAR(100)
	-- Experiencia
	, @v_company VARCHAR(100)
	, @v_still_works BIT
	, @v_start_date DATE
	, @v_finish_date DATE
	, @v_activities VARCHAR(3000)
	-- AFP
	, @v_afp_id INT
	, @v_associate_code VARCHAR(50)
	, @v_afp_link_date DATE
	, @v_type_contract_id INT
	, @v_modality_id INT
	, @v_role_id INT
	, @v_admision_date DATE
	, @v_user_register VARCHAR(4) = 'SIST'
AS
BEGIN
	DECLARE @v_person_id INT = 0
	DECLARE @v_employeed_id INT = 0
	DECLARE @v_salary DECIMAL(18, 2) = 0.00

	DECLARE @v_user_code VARCHAR(4) 
	DECLARE @v_password VARCHAR(100)
	SET @v_user_code = (
		SELECT CONCAT(	CASE 
							WHEN LEFT(LEFT(@v_names, CHARINDEX(' ', @v_names)), 1) = '' 
								THEN (SELECT CHAR(65 + CAST(RAND() * 26 AS INT))) 
								ELSE  LEFT(LEFT(@v_names, CHARINDEX(' ', @v_names)), 1) END, 
						LEFT(SUBSTRING(@v_names, CHARINDEX(' ', @v_names) + 1, LEN(@v_names) - (CHARINDEX(' ', @v_names) - 1)), 1),
						CASE 
							WHEN LEFT(LEFT(@v_surnames, CHARINDEX(' ', @v_surnames)), 1) = '' 
								THEN (SELECT CHAR(65 + CAST(RAND() * 26 AS INT))) 
								ELSE  LEFT(LEFT(@v_surnames, CHARINDEX(' ', @v_surnames)), 1) END, 
						LEFT(SUBSTRING(@v_surnames, CHARINDEX(' ', @v_surnames) + 1, LEN(@v_surnames) - (CHARINDEX(' ', @v_surnames) - 1)), 1))
	)
	SET @v_password = (
		SELECT (CONCAT(TRIM(LEFT(@v_surnames, CHARINDEX(' ', @v_surnames))), TRIM((SELECT CHAR(65 + CAST(RAND() * 26 AS INT)))), (SELECT CAST((RAND() * 100) + 1 AS INT))))
	)

	INSERT INTO person
	(
		names
		, surnames
		, profile_picture
		, birth_date
		, gender
		, state
		, created_at
	)
	VALUES
	(
		@v_names
		, @v_surnames
		, 'default.png'
		, @v_birthdate
		, UPPER(@v_gender)
		, 1
		, GETDATE()
	)
	SET @v_person_id = @@IDENTITY

	INSERT INTO person_document
	(
		person_id
		, number_document
		, created_at
		, state
		, document_id
		, is_default
	)
	VALUES
	(
		@v_person_id
		, @v_nro_document
		, GETDATE()
		, 1
		, @v_type_document_id
		, 1
	)
	IF LEN(@v_cellphone) > 0
	BEGIN
		INSERT INTO person_cellphone
		(
			number_cellphone
			, operator_id
			, is_default
			, created_at
			, state
			, person_id
		)
		VALUES
		(
			@v_cellphone
			, 1
			, 1
			, GETDATE()
			, 1
			, @v_person_id
		)
	END

	IF LEN(@v_email) > 0
	BEGIN
		INSERT INTO person_email
		(
			person_id
			, email
			, created_at
			, state
		)
		VALUES
		(
			@v_person_id
			, @v_email
			, GETDATE()
			, 1
		)
	END

	-- EXPERIENCIA
	INSERT INTO employeed
	(
		person_id
		, role_id
		, state
		, created_at
		, user_access
		, password
		, admision_date
		, afp_sure_id
		, associate_code
		, afp_link_date
		, type_contract_id
		, modality_id
	)
	VALUES
	(
		@v_person_id
		, @v_role_id
		, 'P'
		, GETDATE()
		, @v_user_code 
		, @v_password  
		, @v_admision_date 
		, @v_afp_id
		, @v_associate_code
		, @v_afp_link_date
		, @v_type_contract_id
		, @v_modality_id
	)
	SET @v_employeed_id = @@IDENTITY

	INSERT INTO employeed_experience
	(
		company
		, still_works
		, start_date
		, finish_date
		, activities
		, created_at
		, state
		, employeed_id
	)
	VALUES
	(
		@v_company
		, @v_still_works
		, @v_start_date
		, @v_finish_date
		, @v_activities
		, GETDATE()
		, 1
		, @v_employeed_id
	)
	-- Salario
	SET @v_salary = (SELECT r.salary_to_pay FROM role r WHERE r.id = @v_role_id)
	INSERT INTO employeed_salary
	(
		salary
		, state
		, user_register
		, created_at
		, employeed_id
	)
	VALUES
	(
		@v_salary
		, 1
		, @v_user_register
		, GETDATE()
		, @v_employeed_id
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_FIRST_ATTENCION_CLINIC_HISTORY]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_FIRST_ATTENCION_CLINIC_HISTORY]
@v_patient_id INT,
@v_weight DECIMAL(18, 2),
@v_disease VARCHAR(2000),
@v_desc_operation VARCHAR(1000),
@v_physical_exploration VARCHAR(1000),
@v_shadow_pain INT,
@v_diagnosis VARCHAR(4000),
@v_desc_medic VARCHAR(3000),
@v_information_additional VARCHAR(4000),
@v_take_medicina BIT,
@v_has_disease BIT,
@v_has_operation BIT,
@v_frecuency_id INT,
@v_packet_id INT
AS
BEGIN
	INSERT INTO patient_state_historic
	(	created_at
		, patient_id
		, state
	)
	VALUES(
		GETDATE()
		, @v_patient_id
		, 'C'
	)

	INSERT INTO clinic_history
	(	patient_id
		, weight
		, disease_description
		, has_disease
		, have_some_operation
		, clinical_operation
		, physical_exploration
		, pain_threshold
		, diagnosis
		, take_some_medication
		, medicines
		, packet_or_unit_session_id
		, frecuency_id
		, created_at
		, state
	)
	VALUES(@v_patient_id
		, @v_weight
		, @v_disease
		, @v_has_disease
		, @v_has_operation
		, @v_desc_operation
		, @v_physical_exploration
		, @v_shadow_pain
		, @v_diagnosis
		, @v_take_medicina
		, @v_desc_medic
		, @v_packet_id
		, @v_frecuency_id
		, GETDATE()
		, 1
	)
	
	UPDATE patient 
	SET state = 'C'
	WHERE id = @v_patient_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_MESSAGE_POST_MESSAGE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_MESSAGE_POST_MESSAGE]
	@v_message_content VARCHAR(MAX)
	, @v_from_id INT
	, @v_to_id INT
	, @v_type_user_to CHAR(1)
	, @v_type_user_from CHAR(1)
AS
BEGIN
	INSERT INTO message
	(
		message_content
		, from_id
		, to_id
		, type_user_to
		, created_at
		, seen
		, state
		, type_user_from
	)
	VALUES
	(
		@v_message_content
		, @v_from_id
		, @v_to_id
		, @v_type_user_to
		, GETDATE()
		, 0
		, 1
		, @v_type_user_from
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_POST_FRECUENCY]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_POST_FRECUENCY]
	@v_description VARCHAR(50)
	, @v_abbreviation VARCHAR(30)
	, @_value INT
AS
BEGIN
	INSERT INTO frecuency
	(
		description
		, abbreviation
		, value
		, created_at
		, state
	)
	VALUES
	(
		@v_description
		, @v_abbreviation
		, @_value
		, GETDATE()
		, 1
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTER_POST_PACKETS_OR_UNIT_SESSIONS]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTER_POST_PACKETS_OR_UNIT_SESSIONS]
	@v_description VARCHAR(100)
	, @v_number_sessions INT
	, @v_cost_per_unit DECIMAL(18, 2)
	, @v_abbreviation VARCHAR(50)
	, @v_maximum_fees_to_pay INT
AS
BEGIN

	INSERT INTO packets_or_unit_sessions
	(
		description
		, created_at
		, number_sessions
		, cost_per_unit
		, abbreviation
		, maximum_fees_to_pay
		, state
	)
	VALUES
	(
		@v_description
		, GETDATE()
		, @v_number_sessions
		, @v_cost_per_unit
		, @v_abbreviation
		, @v_maximum_fees_to_pay
		, 1
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_REGISTRO_FINALIZA_SOLICITUD_POST_PATIENT_SOLICITUDE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REGISTRO_FINALIZA_SOLICITUD_POST_PATIENT_SOLICITUDE]
	@v_patient_id AS INT
	, @v_initial_hour TIME
	, @v_initial_date DATE

AS
BEGIN
	DECLARE @v_index INT = 1

	DECLARE @v_number_sesion INT = 0
	DECLARE @v_frecuency_value INT = 0

	SELECT
		@v_number_sesion = ps.number_sessions,
		@v_frecuency_value = f.value
	FROM patient p
	INNER JOIN clinic_history cc ON cc.patient_id = p.id
	INNER JOIN packets_or_unit_sessions ps ON ps.id = cc.packet_or_unit_session_id
	INNER JOIN frecuency f ON f.id = cc.frecuency_id
	WHERE p.id = @v_patient_id

	WHILE @v_index <= @v_number_sesion
	BEGIN
		--Considerar mejora para dias feriados
		DECLARE @v_initial_date_process DATE
		DECLARE @v_frecuency_value_process INT = @v_frecuency_value
		IF @v_index = 1
		BEGIN
			SET @v_initial_date_process = @v_initial_date
		END
		ELSE
		BEGIN
			SET @v_frecuency_value_process = CASE 
												WHEN DATEPART(dw, @v_initial_date_process) IN(6, 7) THEN @v_frecuency_value + 1 
												ELSE @v_frecuency_value 
											END
			SET @v_initial_date_process = DATEADD(DAY, @v_frecuency_value_process, @v_initial_date_process)
		END
		--INSERTAMOS
		INSERT INTO patient_progress_sesion
		(	patient_id
			, session_number
			, session_date
			, session_hour
			, created_at
			, state
		)
		VALUES
		(	@v_patient_id
			, @v_index
			, @v_initial_date_process
			, CASE WHEN @v_index = 1 THEN @v_initial_hour ELSE NULL END
			, GETDATE()
			, CASE WHEN @v_index = 1 THEN 'A' ELSE 'B' END
		)

		SET @v_index = @v_index + 1
	END

	INSERT INTO patient_state_historic
	(	created_at
		, patient_id
		, state
	)
	VALUES
	(
		GETDATE()
		, @v_patient_id
		, 'D'
	)
	UPDATE patient 
	SET state = 'D'
	WHERE id = @v_patient_id

	UPDATE patient_solicitude
	SET finished = 1, date_finished = GETDATE(), state = 0
	WHERE patient_id = @v_patient_id AND state = 1

END
GO
/****** Object:  StoredProcedure [dbo].[PA_REMOVE_MENU_PERMISO_OPTION_PUT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_REMOVE_MENU_PERMISO_OPTION_PUT]-- 101
	@v_option_item_id INT
AS
BEGIN
	DECLARE @v_option_auth_id INT
	DECLARE @v_size AS INT = 0

	BEGIN TRANSACTION
	SELECT @v_option_auth_id = a.option_auth_id FROM option_items_auth a WHERE a.id = @v_option_item_id  
	UPDATE o 
	SET o.modification_date = GETDATE(), o.state = 0
	FROM option_items_auth o
	WHERE o.id = @v_option_item_id	

	SET @v_size = (SELECT COUNT(1) FROM option_items_auth WHERE option_auth_id = @v_option_auth_id AND state = 1)
	IF @v_size = 0
	BEGIN
		UPDATE option_auth
		SET state = 0, modification_date = GETDATE()
		WHERE id = @v_option_auth_id
	END
	COMMIT
END


 
GO
/****** Object:  StoredProcedure [dbo].[PA_ROLE_POST]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ROLE_POST]
	@v_name VARCHAR(200)
	, @v_abbreviation VARCHAR(200)
	, @v_salary DECIMAL(18, 2)
	, @v_area_id INT
AS
BEGIN
	INSERT INTO role
	(
		name
		, state
		, created_at
		, abbreviation
		, salary_to_pay
		, area_id
	)
	VALUES
	(
		@v_name
		, 1
		, GETDATE()
		, @v_abbreviation
		, @v_salary
		, @v_area_id
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ROUTE_GET_ROUTES]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ROUTE_GET_ROUTES]
	@v_employeed_id AS INT
AS
BEGIN
	SELECT 
		r.id
		, r.[path]
		, ISNULL(r.exact, 0) AS exact
		, r.[name]
		, ISNULL(r.element, '') AS element
	FROM [routes] r
	INNER JOIN routes_auth ra ON ra.routes_id = r.id
	WHERE ra.state = 1 AND ra.employeed_id = @v_employeed_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_ROUTES_SPECIAL_GET_ROUTES]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_ROUTES_SPECIAL_GET_ROUTES]
	@v_user_access AS VARCHAR(20)
AS
BEGIN
	SELECT 
		r.name
		, r.id
	FROM [routes] r
	INNER JOIN [routes_auth] ra ON ra.routes_id = r.id
	WHERE r.special = 1 AND ra.employeed_id = (
		SELECT e.id
		FROM employeed e
		WHERE e.user_access = RTRIM(LTRIM(@v_user_access))
	)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SALEBUY_GET_ALL_MOVEMENT_SALE_BUTOUT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_SALEBUY_GET_ALL_MOVEMENT_SALE_BUTOUT]
AS
BEGIN
	SELECT DISTINCT
		UPPER(o.name) AS operation_description
		, m.id
		, m.code_movement
		, psc.amount AS total_pay
		, CAST(psc.amount * 0.18 AS DECIMAL(18, 2)) AS igv
		, CAST((psc.amount - (psc.amount * 0.18)) AS DECIMAL(18, 2)) AS sub_total
		, ISNULL(ms.serie, '') AS serie
		, ISNULL(ms.number, '') AS number
		, pm.description
		, m.created_at
		, UPPER(CONCAT(pee.names, ' ', pee.surnames)) AS person
		, CASE WHEN MS.type_transaction = 'V' THEN 'VENTA' ELSE 'COMPRA' END type_transaction
		, CASE WHEN MS.type_transaction = 'V' THEN 2 ELSE 4 END type_transaction_value
	FROM movement m
	INNER JOIN movement_pay pa ON pa.movement_id = m.id
	INNER JOIN payment_schedule_way_to_pay pss ON pss.id = pa.payment_sche_way_id
	INNER JOIN payment_schedule psc ON psc.id = pss.payment_schedule_id
	LEFT JOIN movement_sale_buyout ms ON ms.movement_id = m.id AND ms.state = 1
	INNER JOIN operation_type o ON o.operation_code = m.code_movement
	LEFT JOIN pay_method pm ON pm.id = ms.payment_method_id
	INNER JOIN customer cc ON cc.id = ms.customer_id
	INNER JOIN person pee ON pee.id	= cc.person_id
	WHERE m.flag = 0 AND m.code_movement = '100000' -- COBROS PENDIENTES
	UNION ALL 
	SELECT 
		UPPER(o.name) AS operation_description
		, m.id
		, m.code_movement
		, ms.total
		, ms.igv
		, ms.sub_total
		, ms.serie
		, ms.number
		, pm.description
		, m.created_at
		, UPPER(CONCAT(pee.names, ' ', pee.surnames)) AS person
		, CASE WHEN MS.type_transaction = 'V' THEN 'VENTA' ELSE 'COMPRA' END type_transaction
		, CASE WHEN MS.type_transaction = 'V' THEN 2 ELSE 4 END type_transaction_value
	FROM movement m
	INNER JOIN movement_sale_buyout ms ON ms.movement_id = m.id AND ms.state = 1
	INNER JOIN operation_type o ON o.operation_code = m.code_movement
	LEFT JOIN pay_method pm ON pm.id = ms.payment_method_id
	INNER JOIN customer cc ON cc.id = ms.customer_id
	INNER JOIN person pee ON pee.id	= cc.person_id
	WHERE m.flag = 0 AND ms.type_transaction = 'V' AND m.code_movement = '100001' -- VENTAS
	ORDER BY serie, number DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SCHEDULE_DISPONIBILTY_GET_PATIENT_PROGRESS_SESION]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_SCHEDULE_DISPONIBILTY_GET_PATIENT_PROGRESS_SESION]  -- 1, '2023-07-29'
	@v_employeed_id INT
	, @v_date_attention DATE
AS
BEGIN
	DECLARE @v_hour_initial TIME = (SELECT dbo.fu_return_value_config('hora_inicio_jornada_laboral'))
	DECLARE @v_index INT = 1
	DECLARE @v_size INT = 9
	DECLARE @v_hour_config_value INT = (SELECT dbo.fu_return_value_config('tiempo_cita_programada'))
	DECLARE @v_minute_between_hours_config_value INT = (SELECT dbo.fu_return_value_config('minutos_entre_horas'))
	DECLARE @v_personal VARCHAR(1000) = ''

	CREATE TABLE #tbl_horarios
	( 
		id INT IDENTITY(1, 1)
		, hour_initial VARCHAR(8)
		, hour_finished VARCHAR(8) 
		, full_names VARCHAR(1000)
	)

	CREATE TABLE #tbl_horarios_empleado
	( 
		id INT IDENTITY(1, 1)
		, hour_reserved VARCHAR(8)
		, full_names VARCHAR(1000)
	)
 
	WHILE @v_index <= @v_size
	BEGIN
		DECLARE @v_hour_for_initial TIME
		DECLARE @v_hour_for_finish TIME
		IF @v_index = 1
		BEGIN
			SET @v_hour_for_initial = @v_hour_initial
			SET @v_hour_for_finish = DATEADD(MINUTE, @v_hour_config_value, @v_hour_initial)
		END
		ELSE
		BEGIN
			SET @v_hour_for_initial = DATEADD(MINUTE, @v_minute_between_hours_config_value, DATEADD(MINUTE, @v_hour_config_value, @v_hour_for_initial))
			SET @v_hour_for_finish = DATEADD(MINUTE, @v_minute_between_hours_config_value, DATEADD(MINUTE, @v_hour_config_value, @v_hour_for_finish))
		END
		-- Verificamos si tiene algun horario asignado el trabajador
		INSERT INTO #tbl_horarios(hour_initial, hour_finished)
		VALUES(CAST(@v_hour_for_initial AS VARCHAR(8)), CAST(@v_hour_for_finish AS VARCHAR(8)))

		SET @v_index = @v_index + 1
	END
	SET @v_index = 1

	INSERT INTO #tbl_horarios_empleado(hour_reserved, full_names)
	SELECT CAST(p.session_hour AS VARCHAR(8)), (CONCAT(pe.surnames, '/', pe.names))
	FROM patient_progress_sesion p 
	LEFT JOIN employeed em ON em.id = p.employeed_id 
	LEFT JOIN person pe ON pe.id = em.person_id
	WHERE p.employeed_id = @v_employeed_id AND p.session_date = @v_date_attention AND ISNULL(p.attended, 0) = 0

	WHILE @v_index <= (SELECT COUNT(1) FROM #tbl_horarios_empleado)
	BEGIN
		DECLARE @v_schedule_time TIME

		SELECT @v_schedule_time = e.hour_reserved, @v_personal = E.full_names FROM #tbl_horarios_empleado e WHERE e.id = @v_index
	
		 
		DELETE FROM #tbl_horarios WHERE id IN (SELECT T.id 
			FROM #tbl_horarios t
			WHERE LEFT(t.hour_initial, 2) = LEFT(CAST(@v_schedule_time AS VARCHAR(8)), 2) 
		)
		UPDATE #tbl_horarios SET full_names = @v_personal
		WHERE id = @v_index
		SET @v_index = @v_index + 1
	END
	SET @v_personal = (SELECT UPPER(CONCAT(pe.surnames, '/', pe.names)) FROM employeed em INNER JOIN person pe ON pe.id = em.person_id WHERE em.id = @v_employeed_id)
	SELECT t.hour_initial
		, t.hour_finished
		, 1 AS state
		, @v_date_attention AS date_attention
		, 'Hora libre' AS reason
		, @v_personal AS persona_cargo
		, CONCAT(@v_date_attention, ' ', t.hour_initial) AS start_hour_initial
		, CONCAT(@v_date_attention, ' ', t.hour_finished) AS finished_hour_finished
	FROM #tbl_horarios t

	DROP TABLE #tbl_horarios
	DROP TABLE #tbl_horarios_empleado
  
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SCHEDULE_SESSIONS_GET_BY_ID_EMPLOYEED]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_SCHEDULE_SESSIONS_GET_BY_ID_EMPLOYEED]
	@v_employeed_id INT
AS
BEGIN
	DECLARE @v_hour_config_value INT = (SELECT dbo.fu_return_value_config('tiempo_cita_programada'))

	SELECT 
		UPPER(ps.description) AS name
		, CONCAT(e.session_date, ' ', e.session_hour) AS startDateTime
		, CONCAT(e.session_date, ' ', DATEADD(MINUTE, @v_hour_config_value, e.session_hour)) AS endDateTime
		, ps.id AS state
	FROM patient_progress_sesion e
	INNER JOIN patient_progress_sesion_state ps ON ps.abbreviation = e.state
	WHERE e.employeed_id = @v_employeed_id  
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SEEN_UPDATE_MESSAGE]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PA_SEEN_UPDATE_MESSAGE]
	@v_to_id INT
	, @v_from_id INT
AS
BEGIN
	UPDATE message
	SET seen = 1, seen_date = GETDATE()
	WHERE (from_id = @v_from_id AND to_id = @v_to_id) OR (from_id = @v_to_id AND to_id = @v_from_id)
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SESSIONS_PATIENT_GETBYID_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_SESSIONS_PATIENT_GETBYID_PATIENT] -- 1
@v_patient_id INT
AS
BEGIN
	SELECT
		pps.id
		, pps.session_date
		, ISNULL(CAST(pps.session_hour AS VARCHAR(8)), '') AS session_hour
		, pps.session_number
		, dbo.fu_return_value_config('tiempo_cita_programada') AS time_demoration
		, ISNULL(pps.attended, 0) AS attended
		, ISNULL(pps.on_hold, 0) AS on_hold
		, dbo.fu_return_system_hour(pps.session_hour) AS system_hour
		, ISNULL(pps.is_flag, 0) AS is_flag
		, UPPER(ps.description) AS state
		, ISNULL(pps.employeed_id, 0) AS employeed_id
	FROM patient p
	INNER JOIN patient_progress_sesion pps ON pps.patient_id = p.id
	INNER JOIN patient_progress_sesion_state ps ON ps.abbreviation = pps.state
	WHERE p.id = @v_patient_id
	ORDER BY pps.session_number ASC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_SOLICITUDE_APPROVE_GET_BY_ID_PATIENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_SOLICITUDE_APPROVE_GET_BY_ID_PATIENT] --
@v_employeed_id AS INT
AS
BEGIN
	SELECT
		p.id
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, ps.date_attention
		, ps.hour_attention
		, UPPER(pst.description) AS reason
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, dbo.fu_return_value_config('tiempo_cita_inicial') AS time
		, pe.profile_picture
		, pe.birth_date
		, pd.number_document
		, pemm.names
		, pemm.surnames
		, pemail.email
		, dbo.fu_return_system_hour(ps.hour_attention) AS system_hour
		, p.user_name
	FROM patient p
	INNER JOIN patient_solicitude ps ON ps.patient_id = p.id
	INNER JOIN person pe ON pe.id = p.person_id
	INNER JOIN patient_state pst ON pst.abbreviation = p.state
	INNER JOIN employeed em ON em.id = ps.employeed_id
	INNER JOIN person pemm ON pemm.id = em.person_id
	LEFT JOIN person_document pd ON pd.person_id = pe.id
	LEFT JOIN person_email pemail ON pemail.person_id = pe.id AND pemail.state = 1
	WHERE em.id = @v_employeed_id AND p.state = 'B'
	ORDER BY ps.created_at DESC
END
GO
/****** Object:  StoredProcedure [dbo].[PA_TYPE_CONTRACT_IN_COMBO_GET_TYPE_OF_CONTRACT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_TYPE_CONTRACT_IN_COMBO_GET_TYPE_OF_CONTRACT]
AS
BEGIN
	SELECT 
		t.id AS value
		, CONCAT(t.name, ' - [', t.abbreviation, ']') AS label
	FROM type_of_contract t
	WHERE t.state = 1
END
GO
/****** Object:  StoredProcedure [dbo].[PA_UPDATE_FRECUENCY_PUT_FRECUENCY]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_UPDATE_FRECUENCY_PUT_FRECUENCY]
	@v_frecuency_id INT
	, @v_description VARCHAR(50)
	, @v_abbreviation VARCHAR(30)
	, @v_value INT
AS
BEGIN
	UPDATE frecuency
	SET description = @v_description
		, abbreviation = @v_abbreviation
		, value = @v_value
		, modificaton_date = GETDATE()
	WHERE id = @v_frecuency_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_UPDATE_HOUR_EMPLOYEED_UPDATE_PATIENT_PROGRESS_SESION]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_UPDATE_HOUR_EMPLOYEED_UPDATE_PATIENT_PROGRESS_SESION]
	@v_employeed_id INT
	, @v_patient_progress_id INT
	, @v_patient_hour_off_attention TIME
	--, @v_date_of_attention DATE
AS
BEGIN
	UPDATE patient_progress_sesion
	SET employeed_id = @v_employeed_id
		, session_hour = @v_patient_hour_off_attention
		, modification_date = GETDATE()
		, state = 'A'
		--, session_date = @v_date_of_attention
	WHERE id = @v_patient_progress_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_UPDATE_PACKETS_PUT_PACKETS_OR_UNIT_SESSIONS]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM packets_or_unit_sessions

CREATE PROCEDURE [dbo].[PA_UPDATE_PACKETS_PUT_PACKETS_OR_UNIT_SESSIONS]
	@v_packet_id INT
	, @v_number_sessions INT
	, @v_cost_per_unit DECIMAL(18, 2)
	, @v_abbreviation VARCHAR(30)
	, @v_maximum_fees_to_pay INT
	, @v_description VARCHAR(50)
AS
BEGIN
	UPDATE packets_or_unit_sessions
	SET description = @v_description
		, number_sessions = @v_number_sessions
		, cost_per_unit = @v_cost_per_unit
		, abbreviation = @v_abbreviation
		, maximum_fees_to_pay = @v_maximum_fees_to_pay
		, modification_date = GETDATE()
	WHERE id = @v_packet_id
END
GO
/****** Object:  StoredProcedure [dbo].[PA_VERIFY_GET_BY_NAMES_PERSON]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_VERIFY_GET_BY_NAMES_PERSON]
	@v_surnames VARCHAR(50)
	, @v_names VARCHAR(100)
AS
BEGIN
	DECLARE @v_person_id INT
	DECLARE @v_nombres_completos VARCHAR(300) = ''
	DECLARE @v_is_exists_person BIT = 0

	SELECT 
		@v_person_id = p.id
		, @v_nombres_completos = CONCAT(p.names, ' ', p.surnames)
	FROM person p
	WHERE p.surnames LIKE @v_surnames + '%' AND p.names LIKE @v_names + '%' AND p.state = 1

	IF EXISTS(SELECT pa.id FROM patient pa WHERE pa.person_id = @v_person_id)
	BEGIN
		SET @v_is_exists_person = 1
		SELECT @v_nombres_completos AS nombres_completos, @v_is_exists_person AS is_exists_person
	END
	ELSE
	BEGIN
		SELECT @v_nombres_completos AS nombres_completos, @v_is_exists_person AS is_exists_person
	END
END
GO
/****** Object:  StoredProcedure [dbo].[PA_VERIFY_IS_PATIENT_ACTIVE_GET_BY_NAMES_PERSON]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_VERIFY_IS_PATIENT_ACTIVE_GET_BY_NAMES_PERSON] --'CRUZADO SIFUENTES', 'KATHERINE NOEMI'
	@v_surnames VARCHAR(50)
	, @v_names VARCHAR(100)
AS
BEGIN
	DECLARE @v_person_id INT
	DECLARE @v_nombres_completos VARCHAR(300) = ''
	DECLARE @v_is_exists_person INTEGER = 0

	SELECT 
		@v_person_id = p.id
		, @v_nombres_completos = CONCAT(p.names, ' ', p.surnames)
	FROM person p
	WHERE p.surnames LIKE '%' + RTRIM(LTRIM(@v_surnames)) + '%' AND p.names LIKE '%' + RTRIM(LTRIM(@v_names)) + '%' AND p.state = 1

	IF EXISTS(SELECT pa.id FROM patient pa WHERE pa.person_id = @v_person_id AND pa.state NOT IN('E'))
	BEGIN
		SET @v_is_exists_person = 1
		SELECT @v_nombres_completos AS nombres_completos, @v_is_exists_person AS is_exists_person
	END
	ELSE
	BEGIN
		SELECT @v_nombres_completos AS nombres_completos, @v_is_exists_person AS is_exists_person
	END
END
GO
/****** Object:  StoredProcedure [dbo].[PA_VO_DOC_GET_VOUCHER_DOCUMENT]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PA_VO_DOC_GET_VOUCHER_DOCUMENT]
AS
BEGIN
	SELECT 
		id
		, CONCAT(name , ' [', abbreviation, ']') AS name
	FROM voucher_document
	ORDER BY id ASC
END
GO
/****** Object:  StoredProcedure [dbo].[stp_get_all_document]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stp_get_all_document]
AS
BEGIN
	SELECT id AS value, abbreviation AS label, size 
	FROM document

END
GO
/****** Object:  StoredProcedure [dbo].[stp_get_all_employeed]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stp_get_all_employeed]
AS
BEGIN
	SELECT e.id AS employeedId,
		CONCAT('[', e.id, '] - ', UPPER(pe.surnames), ', ', UPPER(pe.names)) AS label
		, UPPER(pe.names) AS names
		, UPPER(pe.surnames) AS surnames
		, pe.profile_picture AS profilePicture
		, r.id AS roleId
		, UPPER(r.name) AS role
		, UPPER(ps.description) AS state
		, e.admision_date
		, dbo.fu_return_current_age(pe.birth_date) AS age
		, UPPER(e.user_access) AS user_access
		, CAST(DATEDIFF(DAY, e.admision_date, GETDATE()) / 12 AS DECIMAL(18, 2)) AS vacation_days
		, pe.birth_date
		, es.salary
		, E.user_name
		, a.id AS area_id
		, UPPER(ISNULL(a.description, '')) AS area
		, UPPER(ISNULL(cam.name, '')) AS campus_name
	FROM employeed e
	INNER JOIN person pe ON pe.id = e.person_id
	LEFT JOIN person_document pd ON pd.person_id = pe.id
	INNER JOIN role r ON r.id = e.role_id
	INNER JOIN employeed_state ps ON ps.abbreviation = e.state
	INNER JOIN employeed_salary es ON es.employeed_id = e.id AND es.state = 1
	LEFT JOIN area a ON a.id = r.area_id
	INNER JOIN campus cam ON cam.id = e.campus_id
	WHERE e.state = 'A' AND e.termination_date IS NULL
END
GO
/****** Object:  StoredProcedure [dbo].[stp_get_count_patients_types]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stp_get_count_patients_types]
AS
BEGIN

	SELECT 5 AS size, 'Pendientes de atención' AS description, 'warning' AS type
	UNION ALL
	SELECT 3 AS size, 'Pacientes Atendidos' AS description, 'success' AS type
END
GO
/****** Object:  StoredProcedure [dbo].[stp_post_register_new_solicitude_attention]    Script Date: 14/10/2023 17:34:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stp_post_register_new_solicitude_attention]
	@v_names AS VARCHAR(150) = NULL,
	@v_surNames AS VARCHAR(150),
	@v_birthDate AS DATE,
	@v_documentId AS INT = NULL,
	@v_documentNro AS VARCHAR(15),
	@v_reservedDay AS DATE,
	@v_hourReservedDay AS TIME,
	@v_employeedId AS INT = NULL,
	@v_save_in_draft AS BIT,
	@v_cellphone AS VARCHAR(15),
	@v_email AS VARCHAR(60),
	@v_gender AS CHAR(1)
AS
BEGIN
	
	DECLARE @v_patient_id INT = 0
	DECLARE @v_person_id INT = 0

	SELECT 
		@v_person_id = p.id
	FROM person p
	WHERE p.surnames LIKE '%' + RTRIM(LTRIM(@v_surnames)) + '%' AND p.names LIKE '%' + RTRIM(LTRIM(@v_names)) + '%' AND p.state = 1

	IF NOT EXISTS(SELECT pa.id FROM person pa WHERE pa.id = @v_person_id AND pa.state = 1)
	BEGIN
		INSERT INTO person(names, surnames, profile_picture, birth_date, address, civil_status, gender, state, created_at)
		VALUES(@v_names, @v_surNames, 'default.png', @v_birthDate, '', '', @v_gender, 1, GETDATE())
		SET @v_person_id = @@IDENTITY

		INSERT INTO person_document(person_id, number_document, created_at, state, document_id, is_default)
		VALUES(@v_person_id, @v_documentNro, GETDATE(), 1, @v_documentId, 1)

		INSERT INTO person_email(person_id, email, created_at, state)
		VALUES(@v_person_id, @v_email, GETDATE(), 1)
	END
	
	INSERT INTO patient(person_id, save_to_draft, state, created_at)
	VALUES(@v_person_id, @v_save_in_draft, 'A', GETDATE())
	SET @v_patient_id = @@IDENTITY

	INSERT INTO patient_solicitude(employeed_id, hour_attention, date_attention, created_at, state, patient_id)
	VALUES(CASE WHEN @v_employeedId = 0 THEN NULL ELSE @v_employeedId END, @v_hourReservedDay, @v_reservedDay, GETDATE(), 1, @v_patient_id)

	-- ESTADO INICIAL
	INSERT INTO patient_state_historic(created_at, patient_id, state)
	VALUES(GETDATE(), @v_patient_id, 'A')
	
END
GO
