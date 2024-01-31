-- Get row count of mssql tables
SELECT 
    QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.name) AS [TableName],
    SUM(p.rows) AS [RowCount]
FROM 
    sys.objects sOBJ
JOIN 
    sys.partitions p ON sOBJ.object_id = p.object_id
WHERE 
    sOBJ.name in ('insertTableNameHere')
	and sOBJ.type = 'U'
    AND p.index_id IN (0, 1)
GROUP BY 
    sOBJ.schema_id, sOBJ.name;


-- Search mssql table
SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT
FROM pfsdb.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = N'tblincome';
;
