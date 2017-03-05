SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

/**************** DROP IF EXISTS ****************/
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

GO

/* =============================================

  Created by:    Enrique Sierra Gutiérrez.
  Creation Date: 2017-03-05

  Description: Procedimiento almacenado 
  encargado de eliminar las sesiones de usuario
  que superen el tiempo maximo en minutos permitido
  de inactividad.

============================================= */

CREATE PROCEDURE [dbo].EMP_SPD_TerminarSesionesInactivas               
AS
BEGIN 
  DECLARE
    @HOY DATETIME,
    @master_dbid INT,
    @r_acceso_id INT,
    @r_spid INT,
    @r_Empresa VARCHAR(5),
    @r_Sucursal INT,
    @r_Usuario CHAR(10),
    @query NVARCHAR(500)

  SET @HOY = GETDATE()
  SET @master_dbid = DB_ID('master')

  -- Elimina todas las sesiones de IntelisisET que no tengan
  -- un acceso correspondiente.
  DELETE et
  FROM
    master.dbo.IntelisisET et
  LEFT JOIN Acceso ON Acceso.Empresa = et.Empresa
                  AND Acceso.Sucursal = et.Sucursal
                  AND Acceso.Usuario = et.Usuario
                  AND Acceso.FechaRegistro IS NOT NULL
                  AND Acceso.FechaSalida IS NULL
  WHERE 
    Acceso.ID IS NULL

  -- Elimina las sesiones de los usuarios que superen
  -- los minutos maximos permitidos de inactividad.
  DECLARE cr_SesionesInactivas CURSOR LOCAL FAST_FORWARD
  FOR
  SELECT DISTINCT
    acceso.ID,
    acceso.SPID,
    acceso.Empresa,
    acceso.Sucursal,
    acceso.Usuario
  FROM 
    Usuario u
  JOIN Acceso ON  Acceso.Usuario = u.Usuario
              AND Acceso.FechaRegistro IS NOT NULL
              AND Acceso.FechaSalida IS NULL
  JOIN sys.sysprocesses sys_procs ON sys_procs.SPID = Acceso.SPID
  JOIN master.dbo.IntelisisET et ON et.Empresa = Acceso.Empresa
                                AND et.Sucursal = Acceso.Sucursal
                                AND et.Usuario = Acceso.Usuario
  OUTER APPLY(
              SELECT TOP 1              
                [Time] = st.last_execution_time,
                [Query] = sql_text.TEXT,
                [DB_NAME] = DB_NAME(qp.dbid)
              FROM
                sys.dm_exec_query_stats AS st
              CROSS APPLY sys.dm_exec_sql_text(st.sql_handle) AS sql_text
              LEFT JOIN sys.dm_exec_cached_plans cp ON cp.plan_handle = st.plan_handle
              OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
              WHERE
                qp.dbid = sys_procs.dbid
              AND qp.dbid <> @master_dbid
              AND dbo.RegExIsMatch('^\/\*\s' 
                                  + LTRIM(RTRIM(u.Usuario))
                                  + '\s.*\*\/'
                                  , sql_text.TEXT
                                  , 3) = 1
              ORDER BY
                st.last_execution_time DESC
              ) last_batch
  -- calc
  CROSS APPLY(
              SELECT 
                MinutosInactivo = DATEDIFF(minute, last_batch.[Time], GETDATE())
              ) calc
  WHERE 
    u.EMP_MinutosMaximosDeInactividad IS NOT NULL
  AND sys_procs.status = 'sleeping'
  AND sys_procs.blocked = 0
  AND calc.MinutosInactivo > u.EMP_MinutosMaximosDeInactividad

  OPEN cr_SesionesInactivas

  FETCH NEXT FROM cr_SesionesInactivas
  INTO @r_acceso_id, @r_spid, @r_Empresa,@r_Sucursal, @r_Usuario
  
  WHILE @@fetch_status = 0
  BEGIN

    DELETE master.dbo.IntelisisET 
    WHERE Empresa = @r_Empresa
      AND Sucursal = @r_Sucursal
      AND Usuario = @r_Usuario
     
    SET @query =  
"BEGIN TRY 
  KILL " + CAST(@r_spid AS VARCHAR(5))+ "
END TRY 
BEGIN CATCH
  PRINT
  (  
      'Unable to kill the SPID "
    + CAST(@r_spid AS VARCHAR(5)) + "'
    + '. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR)
    + ', Message: ' + ERROR_MESSAGE()
    + CHAR(13)
  )
END CATCH"
  
    EXECUTE sp_executesql @query
    
    UPDATE Acceso
    SET FechaSalida = @HOY
    WHERE ID = @r_acceso_id
      
    FETCH NEXT FROM cr_SesionesInactivas
    INTO @r_acceso_id, @r_spid, @r_Empresa,@r_Sucursal, @r_Usuario

  END  
  
  CLOSE cr_SesionesInactivas

  DEALLOCATE cr_SesionesInactivas

END