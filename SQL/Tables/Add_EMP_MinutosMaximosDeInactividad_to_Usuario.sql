IF NOT EXISTS
(
  SELECT
    COLUMN_NAME 
  FROM
    INFORMATION_SCHEMA.COLUMNS
  WHERE 
      [TABLE_SCHEMA] = 'dbo'
  AND [TABLE_NAME]   = 'Usuario'
  AND [COLUMN_NAME]  = 'EMP_MinutosMaximosDeInactividad'
)
BEGIN
  ALTER TABLE Usuario
  ADD EMP_MinutosMaximosDeInactividad INT NULL;
END