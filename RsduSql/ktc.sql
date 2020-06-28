DECLARE 
@idvti as int,
@START_INTERVAL AS DATETIME, 
@END_INTERVAL AS DATETIME, 
@TIMESTAMP AS INT,
@idreq  AS DATETIME, 
@TimeStart  AS DATETIME, 
@TimeEnd AS DATETIME;

-- ���������� ��������� �������, � �������� ������� � ���� ����� ������ ������ ������� ��������
SELECT @START_INTERVAL =  DATEADD(mi,-5,GETDATE()); --GETDATE();  
SELECT @END_INTERVAL = GETDATE(); -- DATEADD(hh,24,GETDATE()); DATEADD(dd,-1,GETDATE());
-- �������� ������� ����� ������� �� ����� �������
SELECT @TIMESTAMP = CAST(DATEDIFF(ss , '19700101 00:00:00.000' , GETUTCDATE()) AS INT);

set @idvti=12675;

delete from [e6work].[dbo].[VTIdataList]  where [idvti]=@idvti; 

-- ���������� ������������ ������ � ����������� ������� �� ��� (�� ���������) ����� �������� ���������
EXECUTE [e6work].[dbo].[ep_Askvtidata]
@cmd='List', 
@idvti=@idvti, --���� ��������� ������� idVTI ������� ���������
@idreq=@TIMESTAMP, 
@TimeStart=@START_INTERVAL, 
@TimeEnd=@END_INTERVAL;

-- ������ ����� ����� ����� ������ ��������� �������� �� ��������� ������� � �� ���
 -- SELECT * FROM [e6work].[dbo].[VTIdataList] WHERE [idVTI] = @idvti AND [ValueFL] IS NOT NULL;

-- ������ ������� ��������� ������� ��� �� �������
-- EXECUTE [e6work].[dbo].[ep_Askvtidata] @cmd='Clear', @idreq=@TIMESTAMP;