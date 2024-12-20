USE []	--use appropriate database
GO
/****** Object:  StoredProcedure [dbo].[CheckDupsV2]    Script Date: 9/28/2023 1:11:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 Create or ALTER Procedure [dbo].[CheckDupsV2](	@AuditName Varchar(20)='ALL',
											@DATASETNAME VARCHAR(50)='ALL',
											@DatabaseName AS VARCHAR(254) = 'ALL',
											@TableName AS VARCHAR(254) = 'ALL',
											@CheckDupKeySetupONly as BIT=0,
											@PassCt AS VARCHAR(254) = 'ALL') AS 

BEGIN
	DECLARE @PrtMsg AS VARCHAR(8000);
	DECLARE @SqlString AS VARCHAR(8000);
	DECLARE @Now SMALLDATETIME, @End AS SMALLDATETIME;
	DECLARE @Error AS INT;
	DECLARE @RowCt AS INT;
	DECLARE @FieldList AS VARCHAR(8000)
	DECLARE @MaxId AS VARCHAR(254)
	DECLARE @WhereClause AS VARCHAR(254)
	DECLARE @HavingClause AS VARCHAR(254)
	DECLARE @MinMaxId AS BIT
	DECLARE @TableNameDeletes as Varchar(254)
	DECLARE @DatabaseNameDeletes as Varchar(254) 
	DECLARE @SaveDupRecords as BIT
	DECLARE @LoopCt AS INT
	DECLARE @StMinMax AS VARCHAR(3)
	DECLARE @StSign AS VARCHAR(1)
	DECLARE @CurrPos AS INT
	DECLARE @SplitField AS VARCHAR(254)
	DECLARE @Item_table TABLE (
								Primary_Key INT IDENTITY(1,1) NOT NULL, 
								ItemID INT,
								DatabaseName Varchar(100),
								TableName Varchar(100),
								TblCat Varchar(10),
								DupCounts int Default 0,
								NullCnts int Default 0);
	Drop table if exists dbo.##DupResults;
	Create table ##DupResults(
			Primary_Key INT IDENTITY(1,1) NOT NULL,
			DatabaseName Varchar(255),
			TableName Varchar(255),
			DupCounts Int,
			NullCnt int)


	SET NOCOUNT ON;

	
	SET @PrtMsg =  'Getting the tables to check dups In …………………………………………………………………………………';
	Print @PrtMsg
	BEGIN TRY 
					
				Drop table if exists dbo.##temp;
				--Create Table ##Temp(
				--	DatabaseName Varchar(255),
				--	Tablename Varchar(8000)
				--	)
				--Set @SqlString='Insert into ##temp
				--SELECT distinct TM.DatabaseName,
				--       Replace(TM.tablename, ''DBO.'', '''') as TableName  
				--FROM   '+@TrackerDB+'.[DBO].[tracking_datasets] TD
				--       INNER JOIN '+@TrackerDB+'.dbo.[tracking_datasetdetail] TDD
				--               ON TD.datasetid = TDD.datasetid
				--       INNER JOIN '+@TrackerDB+'.[DBO].[tracking_maps] TM
				--               ON TM.detailid = TDD.detailid 
				--WHERE  '''+@DATASETNAME+''' IN ( ''ALL'', datasetname )
				--       AND '''+@DatabaseName+''' IN (''ALL'', DatabaseName )
				--       AND '''+@TableName+''' IN ( ''ALL'',Replace(TableName,''dbo.'','''' ))
				
				--Union 
				
				--SELECT 
				--	Distinct Column2 as DatabaseName,[Text]
				--FROM 
				--	[dbo].__GlobalWizProcesses
				--WHERE 
				--	FormName = ''CCA_frmWizDupOutWizard''
				--	AND '''+@DatabaseName+''' =Column2
				--	AND '''+@TableName+''' IN ( ''ALL'',Replace(text,''dbo.'','''' ))
				--GROUP BY 
				--	Column2, [Text],ItemID '

				--Set @sqlstring='select * into ##temp from dbo.VW_AllTables'
				--EXEC (@sqlstring);

				INSERT INTO @Item_table (itemid,DatabaseName,TableName,TblCat)
						SELECT Isnull(itemid, 0),MAX(t.databaseName),MAX(t.tablename),MAX(t.TblCat)
								FROM ( Select * from  [dbo].__globalwizprocesses
								WHERE  formname = 'CCA_frmWizDupOutWizard'
								       AND @DatabaseName IN ( 'ALL', column2 )
								       AND @TableName IN ( 'ALL', [text] )
								       AND @PassCt IN ( 'ALL', column8 )) gwp
								       RIGHT JOIN (Select * 
													from dbo.VW_AllTables 
													Where @DatabaseName IN ( 'ALL', DatabaseName)
													  AND @TableName IN ( 'ALL', TableName )
													  And @DATASETNAME IN ('ALL',DataSetName)) t
								               ON gwp.column2 =t.databasename
								                  AND gwp.text = t.tablename
												  
								GROUP  BY DatabaseName,
								          TableName,
								          column8,
								          itemid
								ORDER  BY DatabaseName,
								          TableName,
								          column8
							   
								SET @RowCt =@@ROWCOUNT
	END TRY
	BEGIN CATCH
				SET @PrtMsg='ERROR IN GETTING THE lIST OF TABLES TO CHECK DUPS IN DUE TO:' +char(13);
				SET @PrtMSg =@PrtMSg + ERROR_MESSAGE() +char(13); 
				--SET @PrtMSg=@PrtMsg +'Please check the following query:'+char(13);--+@sqlstring;
				THROW 51000,@PrtMSg,1 
	END CATCH

IF @CheckDupKeySetupONly=0 
BEGIN
Declare @itemid int;
SET @LoopCt = 1
WHILE @LoopCt >= 1 AND @LoopCt <= @RowCt
  BEGIN
      SELECT @DatabaseName =  column2 ,
             @TableName = [text] ,
             @TableNameDeletes = [text] + '_DupDeletes',
             @FieldList = column4,
             @MaxId = column5,
             @WhereClause = column6,
             @HavingClause = column7,
             @PassCt = column8,
             @MinMaxId = COALESCE(column9, 0),
             @SaveDupRecords = Abs(COALESCE(NULLIF(column10, ''), 0)),
             @DatabaseNameDeletes = column11
      FROM   [dbo].__globalwizprocesses GP
             INNER JOIN @Item_table IT
                     ON GP.itemid = IT.itemid
      WHERE  primary_key = @LoopCt
	   

	    Set @itemid=(Select itemid from @Item_table where Primary_Key=@LoopCt )
	    If @itemid<>0
		Begin
		SET @PrtMsg =  'Checking DUPS in (' + @TableName + ') (PASS ' + @PassCt + ')…………………………………………………………………………………'
		RAISERROR(@PrtMsg, 0, 1) WITH NOWAIT
    	

		SET @SqlString ='
    	DECLARE @RecCt AS INT
    	DECLARE @DayTime as DATETIME
    	DECLARE @RecCtBatch AS INT
		DECLARE @PrtMsg as VARCHAR(8000)
    	
    	SET @DayTime = GetDate()
    	SET @PrtMsg =  ''STARTED SELECT: '' + Convert(Varchar(40),@DayTime)
    	RAISERROR(@PrtMsg, 0, 1) WITH NOWAIT

		Insert into ##DupResults(Databasename,Tablename,DupCounts,NullCnt)
		SELECT
			'''+@DatabaseName +''', 
			'''+@TableName +''',Isnull(SUM(1),0) as count
			' 

		Set @SqlString=@SqlString+',Case WHEN ('
		SET @CurrPos = 0
				SET @FieldList = @FieldList + ', '
				WHILE (@CurrPos <= Len(@FieldList))
				BEGIN
				   SET @SplitField = LTRIM(SUBSTRING(@FieldList, @CurrPos, CHARINDEX(',', @FieldList, @CurrPos)-@CurrPos))
				   SET @CurrPos = CHARINDEX(',', @FieldList, @CurrPos) +1
					IF RIGHT(@SplitField, 6) = 'ISNULL'
		                BEGIN
				   SET @SqlString = @SqlString + '  SRC.' + @SplitField + ' IS NULL' 
				END
				ELSE
				   SET @SqlString = @SqlString + '  SRC.' + @SplitField + ' IS NULL'
		
		                   If @CurrPos <= Len(@FieldList) SET @SqlString = @SqlString + ' OR 
	               '
	               END
		Set @SqlString=@SqlString + ') Then 1 ELSE 0 END As NullCnt
		'
		Set @SqlString=@SqlString +'FROM
			' + @DatabaseName + '.dbo.' + @TableName + ' SRC'

		IF COALESCE(@WhereClause,'') != ''
		SET @SqlString = @SqlString + '
		WHERE
			' + @WhereClause 
		
		SET @FieldList=Left(@FieldList,len(@FieldList)-1)
		SET @SqlString = @SqlString + '
		GROUP BY
			' + REPLACE(@FieldList,'ISNULL','') + '
		HAVING
			SUM(1) > 1'

		IF COALESCE(@HavingClause,'') != ''
		SET @SqlString = @SqlString + ' AND 
			' + @HavingClause 

		
		EXEC( @SqlString);
		Print @sqlstring;

		END

		SET @LoopCt = @LoopCt + 1
END 



If ((select count(1) from @Item_table where ItemID=0)=0)
Select 'Every Table has Dup Key SetUp' AS Remark
Else
select DatabaseName,TableName,'No Dup Keys Set Up [Please Verify]' as Remarks
from @Item_table
where ItemID=0

select distinct DatabaseName,TableName,' Dup Keys Available in this Table' as Remarks
from @Item_table
where ItemID<>0




--select Databasename,tablename,sum(dupcounts) as DuplicatesCounts,
--'Exec '+@AuditName+'..__GlobalWizDupOut 0,'''+Replace(Replace(Databasename,'[',''),']','')+''','''+Replace(Replace(Tablename,'[',''),']','')+'''' as DupRemoveQuery
Update itbl 
set DupCounts=DuplicatesCounts,
NullCnts=NullCnt
from @Item_table itbl 
inner join 
(
Select DatabaseName,TableName,sum( DuplicatesCounts) DuplicatesCounts, sum(nullcnt) NullCnt
from(
select Databasename,tablename,Case When Nullcnt=1 then sum(dupcounts) Else 0 END as NullCnt,sum(DupCounts) as DuplicatesCounts 
from ##DupResults
Group by Databasename,Tablename,NullCnt) a 
Group by Databasename,Tablename

) drlts
on itbl.DatabaseName=drlts.DatabaseName
and itbl.TableName=drlts.TableName


--select Databasename,tablename,sum(dupcounts) as DuplicatesCounts,--Case when nullcnt=1 then sum(DupCounts) else 0 end as NullCNT,
--'Exec '+@AuditName+'..__GlobalWizDupOut 0,'''+Replace(Replace(Databasename,'[',''),']','')+''','''+Replace(Replace(Tablename,'[',''),']','')+'''' as DupRemoveQuery
--from ##DupResults
--Group by Databasename,Tablename


select distinct DatabaseName,TableName,TblCat,DupCounts,NullCnts,
'Exec '+@AuditName+'..__GlobalWizDupOut 0,'''+Replace(Replace(Databasename,'[',''),']','')+''','''+Replace(Replace(Tablename,'[',''),']','')+'''' as DupRemoveQuery
from @Item_table 
Where DupCounts<>0

Select distinct DatabaseName,TableName,'No Dups in this Table' as Remarks
from @Item_table 
Where DupCounts=0 and ItemID<>0
END
ELSE
BEGIN
select distinct  DatabaseName,TableName,'No Dup Keys Set Up [Please Verify]' as Remarks
from @Item_table
where ItemID=0

select distinct DatabaseName,TableName,' Dup Keys Available in this Table' as Remarks
from @Item_table
where ItemID<>0


END
	
END

--EXEC dbo.CheckDups