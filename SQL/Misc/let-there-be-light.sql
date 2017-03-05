IF EXISTS
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
  DROP COLUMN EMP_MinutosMaximosDeInactividad;
END

IF EXISTS
(
  SELECT
    name
  FROM
    sysobjects
  WHERE
    name = 'EMP_SPD_TerminarSesionesInactivas'
) 
BEGIN
  DROP PROCEDURE  EMP_SPD_TerminarSesionesInactivas
END