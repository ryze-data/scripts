-- Credit goes to codingtacos github user
with level_one as (
    select
    lower(@@servername) as server_name
    , lower(c.table_catalog) as [database_name]
    , lower(c.table_schema) as table_schema
    , lower(c.table_name) as table_name
    , c.column_name
    from """+db_server+"""."""+db_name+""".information_schema.columns c
    inner join """+db_server+"""."""+db_name+""".information_schema.tables t on t.table_name = c.table_name
    where c.data_type in ('date','datetime','datetime2','smalldatetime')
    and t.table_type = 'BASE TABLE'
    group by
    lower(c.table_catalog)
    , lower(c.table_schema)
    , lower(c.table_name)
    , c.column_name
),
level_two  as (
select  server_name, database_name, table_schema, table_name, CONCAT( N'SELECT * FROM ',LOWER(@@servername),'.', [database_name],'.', table_schema,'.[' , table_name, '] WITH (NOLOCK) where getdate() - """ + days_prior + """ < ', column_name ) single_table_q
from level_one
),
level_three as (
select server_name, database_name, table_schema, table_name, string_agg( cast(single_table_q as nvarchar(max)) , ' union ')  bcpquery
from level_two
group by server_name, database_name, table_schema, table_name
)
select * 
from level_three