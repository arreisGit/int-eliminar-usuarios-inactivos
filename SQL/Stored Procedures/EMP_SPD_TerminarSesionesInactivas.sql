SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
  Creation Date: 2017-03-04

  Description: Procedimiento almacenado 
  encargado de eliminar las sesiones de usuario
  que superen el tiempo maximo en minutos permitido
  de inactividad.

============================================= */

CREATE PROCEDURE [dbo].EMP_SPD_TerminarSesionesInactivas()                
AS BEGIN 
END