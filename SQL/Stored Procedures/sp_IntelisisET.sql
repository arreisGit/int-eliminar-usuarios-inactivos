USE [master];
GO

/****** Object:  StoredProcedure [dbo].[sp_IntelisisET]    Script Date: 04/03/2017 06:27:32 p.m. ******/

SET ANSI_NULLS OFF;
GO

SET QUOTED_IDENTIFIER OFF;
GO

ALTER PROCEDURE [dbo].[sp_IntelisisET]
	@Accion         VARCHAR(20),
	@Estacion       INT,
	@EstacionFirma  VARCHAR(32),
	@Desde          INT         = NULL,
	@Hasta          INT         = NULL,
	@AccesoID       INT         = NULL,
	@Empresa        VARCHAR(5)  = NULL,
	@Sucursal       INT         = NULL,
	@Usuario        VARCHAR(10) = NULL,
	@Licenciamiento VARCHAR(50) = NULL
AS BEGIN
	
  DECLARE
		@TimeOut                  INT,
		@Ahora                    DATETIME,
		@Vencido                  DATETIME,
		@UltimaActualizacion      DATETIME,
		@ultEstacion              INT,
		@crEstacion               INT,
		@Ok                       INT,
		@OkRef                    VARCHAR(255),
		@EliminarUsuarioDuplicado BIT;
	
  SELECT
		@TimeOut = ISNULL(ETTimeOut, 15),
		@EliminarUsuarioDuplicado = EliminarUsuarioDuplicado
	FROM
		IntelisisMK;
	
  SELECT
		@Ahora = GETDATE();

	SELECT
		@Vencido = DATEADD(minute, -@TimeOut, @Ahora);

	SELECT
		@Ok = NULL,
		@OkRef = NULL;

	IF @Accion = 'INSERT'
	BEGIN

		IF @EliminarUsuarioDuplicado = 1
		BEGIN
			IF EXISTS
			(
				SELECT
					*
				FROM
					IntelisisET
				WHERE Usuario = @Usuario
							AND Estacion BETWEEN @Desde AND @Hasta
			)
			BEGIN
				DELETE IntelisisET
				WHERE
					Usuario = @Usuario
					AND Estacion BETWEEN @Desde AND @Hasta
			END
		END;

		SELECT
			@Estacion = NULL;


		SELECT
			@Estacion = (
			              SELECT
				              MAX(Estacion)
			              FROM
				              IntelisisET
			              WHERE
                      Estacion BETWEEN @Desde AND @Hasta

		              );
		IF @Estacion IS NULL
		BEGIN
			SELECT
				@Estacion = @Desde;
		END
		ELSE
		BEGIN
			IF @Estacion = @Hasta
			BEGIN
				SELECT
					@Estacion = NULL,
					@crEstacion = NULL,
					@ultEstacion = @Desde - 1;
				DECLARE crIntelisisET CURSOR LOCAL
				FOR SELECT
							Estacion,
							UltimaActualizacion
						FROM
							IntelisisET
						WHERE Estacion BETWEEN @Desde AND @Hasta
						ORDER BY
							Estacion;
				OPEN crIntelisisET;
				FETCH NEXT FROM crIntelisisET INTO
					@crEstacion,
					@UltimaActualizacion;


				WHILE @@FETCH_STATUS <> -1
							AND @Estacion IS NULL
				BEGIN
					IF @@FETCH_STATUS <> -2
					BEGIN
						IF @crEstacion > @ultEstacion + 1
						BEGIN
							SELECT
								@Estacion = @ultEstacion + 1;
						END
						ELSE
						BEGIN
							IF @TimeOut > 0
									AND @UltimaActualizacion < @Vencido
							BEGIN
								DELETE IntelisisET
								WHERE
									Estacion = @crEstacion;
								SELECT
									@Estacion = @crEstacion;
							END;
						END;
						SELECT
							@ultEstacion = @crEstacion;
					END;
					FETCH NEXT FROM crIntelisisET INTO
						@crEstacion,
						@UltimaActualizacion;
				END;
				CLOSE crIntelisisET;
				DEALLOCATE crIntelisisET;
			END;
			ELSE
			BEGIN
				IF @Estacion < @Hasta
				BEGIN
					SELECT
						@Estacion = @Estacion + 1
				END;
			END;
		END;
		IF @Estacion IS NOT NULL
		BEGIN
			IF NOT EXISTS
			(
				SELECT
					*
				FROM
					IntelisisET
				WHERE EstacionFirma = @EstacionFirma
			)
			BEGIN
				INSERT INTO IntelisisET
				(
					Estacion,
					EstacionFirma,
					Empresa,
					Sucursal,
					Usuario,
					UltimaActualizacion,
					Licenciamiento
				)
				VALUES
				(
					@Estacion,
					@EstacionFirma,
					@Empresa,
					@Sucursal,
					@Usuario,
					@Ahora,
					@Licenciamiento
				);
			END;
			ELSE
			BEGIN
				SELECT
					@Estacion = NULL,
					@Ok = 151;
			END;
		END;
		ELSE
		BEGIN
			SELECT
				@Ok = 152;
		END;
	END;
	ELSE
	BEGIN
		SELECT
			@EstacionFirma = EstacionFirma
		FROM
			IntelisisET
		WHERE Estacion = @Estacion;


		IF @Accion = 'UPDATE'
		BEGIN
			UPDATE IntelisisET WITH(ROWLOCK)
			SET
				UltimaActualizacion = @Ahora
			WHERE
				Estacion = @Estacion;

			IF @@ROWCOUNT = 0
			BEGIN
				SELECT
					@Ok = 153
			END;
		END;


		ELSE
		BEGIN
			IF @Accion = 'DELETE'
			BEGIN
				DELETE IntelisisET
				WHERE
					Estacion = @Estacion
					AND EstacionFirma = @EstacionFirma;
				IF @@ROWCOUNT = 0
				BEGIN
					SELECT
						@Ok = 154
				END;
			END;
		END;
	END;
	SELECT
		'Estacion' = @Estacion,
		'EstacionFirma' = @EstacionFirma,
		'Ok' = @Ok,
		'OkRef' = @OkRef;
END;