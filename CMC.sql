-----VARIABLES BIND
VARIABLE b_fecha VARCHAR2(6);
EXEC :b_fecha := '202301';

VARIABLE p_valor_limite_com NUMBER;
EXEC :p_valor_limite_com := 500000;

DECLARE 
    v_mes_proceso  NUMBER(2);
    v_anno_proceso NUMBER(4);
    v_correlativo  NUMBER := 0;
    v_error_msg    VARCHAR2(200);
    v_error_stmt   VARCHAR2(100);
    v_auditor_info VARCHAR2(100);

    -- CURSOR para auditores
    CURSOR cur_auditor IS
    SELECT
        a.id_auditor,
        a.numrun,
        a.nombre || ' ' || a.appaterno || ' ' || a.apmaterno as nombre_completo,
        a.sueldo,
        a.cod_profesion,
        a.cod_tpcontrato,
        p.nombre_profesion,
        p.nivel_criticidad,
        tc.porc_incentivo
    FROM
        auditor a
        JOIN profesion p ON a.cod_profesion = p.cod_profesion
        JOIN tipo_contrato tc ON a.cod_tpcontrato = tc.cod_tpcontrato;

    -- CURSOR para empresas por auditor
    CURSOR cur_empresas (p_id_auditor NUMBER, p_fecha_proceso VARCHAR2) IS
    SELECT
        cod_empresa,
        SUM(monto_auditoria) AS monto_empresa
    FROM
        auditoria
    WHERE
        id_auditor = p_id_auditor
        AND TO_CHAR(fin_auditoria, 'YYYYMM') = p_fecha_proceso
    GROUP BY
        cod_empresa;

    -- Variables para cálculos
    v_comision_cant_audit    NUMBER(10, 2);
    v_comision_monto_audit   NUMBER(10, 2);
    v_comision_prof_critica  NUMBER(10, 2);
    v_comision_extra         NUMBER(10, 2);
    v_total_comision_audit   NUMBER(10, 2);
    v_total_comision_empresa NUMBER(10, 2);
    v_monto_total_audit      NUMBER(10, 2);
    v_cantidad_auditorias    NUMBER;
    v_porc_total_audit       NUMBER(4,2);
    v_porc_monto_audit       NUMBER(4,2);
    
    -- VARRAY para porcentajes de incentivo
    TYPE tipo_varray_porc_inc IS VARRAY(4) OF NUMBER(5,2);
    varray_porc_inc tipo_varray_porc_inc;
    
BEGIN
    -- Truncar tablas y manejar secuencia
    BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ERROR_PROCESO';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_ERROR_PROCESO START WITH 1 INCREMENT BY 1';
    EXCEPTION
        WHEN OTHERS THEN
            v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
            v_error_stmt := 'TRUNCATE/DROP/CREATE';
            v_error_msg := SQLERRM;
            INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
    END;

    -- Extraer mes y año de :b_fecha
    v_anno_proceso := TO_NUMBER(SUBSTR(:b_fecha, 1, 4));
    v_mes_proceso  := TO_NUMBER(SUBSTR(:b_fecha, -2));
    
    -- Inicializar VARRAY con los porcentajes de incentivo para los tipos de contrato
    varray_porc_inc := tipo_varray_porc_inc(15.00, 10.00, 5.00, 5.00);

    -- Procesar cada auditor
    FOR reg_auditor IN cur_auditor LOOP
        BEGIN
            -- Inicializar variables
            v_comision_cant_audit := 0;
            v_comision_monto_audit := 0;
            v_comision_prof_critica := 0;
            v_comision_extra := 0;
            v_total_comision_audit := 0;
            v_total_comision_empresa := 0;
            v_monto_total_audit := 0;
            v_cantidad_auditorias := 0;
            
            -- Información del auditor para errores
            v_auditor_info := 'Auditor: ' || reg_auditor.numrun || ' - ' || reg_auditor.nombre_completo;

            -- Calcular cantidad de auditorías y monto total
            BEGIN
                SELECT COUNT(*), SUM(monto_auditoria)
                INTO v_cantidad_auditorias, v_monto_total_audit
                FROM auditoria
                WHERE id_auditor = reg_auditor.id_auditor
                AND TO_CHAR(fin_auditoria, 'YYYYMM') = :b_fecha;
                
                -- Si no hay auditorías, registrar error
                IF v_cantidad_auditorias = 0 THEN
                    v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                    v_error_stmt := 'CALCULO_TOTAL_EMPRESA';
                    v_error_msg := 'No se pudo calcular Total Empresa para auditor ' || reg_auditor.id_auditor;
                    INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                    v_error_stmt := 'SELECT COUNT/SUM auditorias';
                    v_error_msg := v_auditor_info || ' - ' || SQLERRM;
                    INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
            END;

            -- Comisión por cantidad de auditorías
            BEGIN
                SELECT porc_total_audit
                INTO v_porc_total_audit
                FROM porc_total_auditorias
                WHERE v_cantidad_auditorias BETWEEN total_audit_min AND total_audit_max
                AND ROWNUM = 1;
                
                v_comision_cant_audit := reg_auditor.sueldo * v_porc_total_audit / 100;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_comision_cant_audit := 0;
                WHEN OTHERS THEN
                    v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                    v_error_stmt := 'SELECT porc_total_auditorias';
                    v_error_msg := v_auditor_info || ' - ' || SQLERRM;
                    INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
                    v_comision_cant_audit := 0;
            END;

            -- Comisión por monto auditado
            BEGIN
                SELECT porc_monto_audit
                INTO v_porc_monto_audit
                FROM porc_monto_auditorias
                WHERE v_monto_total_audit BETWEEN monto_audit_min AND monto_audit_max
                AND ROWNUM = 1;
                
                v_comision_monto_audit := v_monto_total_audit * v_porc_monto_audit;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_comision_monto_audit := 0;
                WHEN OTHERS THEN
                    v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                    v_error_stmt := 'SELECT porc_monto_auditorias';
                    v_error_msg := v_auditor_info || ' - ' || SQLERRM;
                    INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
                    v_comision_monto_audit := 0;
            END;

            -- Comisión por profesión crítica
            IF reg_auditor.nivel_criticidad >= 3 THEN
                v_comision_prof_critica := reg_auditor.sueldo * 0.05;
            END IF;

            -- Comisión extra por tipo de contrato usando VARRAY
            IF reg_auditor.cod_tpcontrato BETWEEN 1 AND 4 THEN
                v_comision_extra := reg_auditor.sueldo * varray_porc_inc(reg_auditor.cod_tpcontrato) / 100;
            ELSE
                v_comision_extra := 0;
            END IF;

            -- Total comisión auditor
            v_total_comision_audit := v_comision_cant_audit + v_comision_monto_audit + 
                                     v_comision_prof_critica + v_comision_extra;

            -- Validar límite de comisión
            IF v_total_comision_audit > :p_valor_limite_com THEN
                v_total_comision_audit := :p_valor_limite_com;
            END IF;

            -- Procesar cada empresa del auditor (solo si hay auditorías)
            IF v_cantidad_auditorias > 0 THEN
                FOR reg_emp IN cur_empresas(reg_auditor.id_auditor, :b_fecha) LOOP
                    BEGIN
                        -- Calcular comisión por empresa
                        IF v_monto_total_audit > 0 THEN
                            v_total_comision_empresa := v_total_comision_audit * (reg_emp.monto_empresa / v_monto_total_audit);
                        ELSE
                            v_total_comision_empresa := 0;
                        END IF;

                        -- Validar límite de comisión por empresa
                        IF v_total_comision_empresa > :p_valor_limite_com THEN
                            v_total_comision_empresa := :p_valor_limite_com;
                        END IF;

                        -- Insertar en detalle
                        INSERT INTO DETALLE_COMISIONES_AUDITORIAS_MES (
                            MES_PROCESO, ANNO_PROCESO, RUN_AUDITOR, NOMBRE_AUDITOR,
                            NOMBRE_PROFESION, COMISION_TOTAL_AUDIT, COMISION_MONTO_AUDIT,
                            COMISION_PROF_CRITICA, COMISION_EXTRA, TOTAL_COMISION_AUDIT,
                            TOTAL_COMISION_EMPRESA, COD_EMPRESA
                        ) VALUES (
                            v_mes_proceso, v_anno_proceso, reg_auditor.numrun, reg_auditor.nombre_completo,
                            reg_auditor.nombre_profesion, v_comision_cant_audit, v_comision_monto_audit,
                            v_comision_prof_critica, v_comision_extra, v_total_comision_audit,
                            v_total_comision_empresa, reg_emp.cod_empresa
                        );
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                            v_error_stmt := 'INSERT DETALLE_COMISIONES';
                            v_error_msg := v_auditor_info || ' - Empresa: ' || reg_emp.cod_empresa || ' - ' || SQLERRM;
                            INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
                    END;
                END LOOP;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
                v_error_stmt := 'Procesamiento auditor';
                v_error_msg := v_auditor_info || ' - ' || SQLERRM;
                INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
        END;
    END LOOP;

    -- Resumen por profesión
    BEGIN
        INSERT INTO RESUMEN_COMISIONES_AUDITORIAS_MES (
            MES_PROCESO, ANNO_PROCESO, NOMBRE_PROFESION, TOTAL_AUDITORES,
            TOTAL_CON_AUDITORIAS, TOTAL_SIN_AUDITORIAS, MONTO_TOTAL_AUDITORIAS,
            MONTO_TOTAL_COMISIONES
        )
        SELECT
            v_mes_proceso,
            v_anno_proceso,
            p.nombre_profesion,
            COUNT(DISTINCT a.id_auditor) AS total_auditores,
            COUNT(DISTINCT CASE WHEN EXISTS (
                SELECT 1 FROM auditoria au 
                WHERE au.id_auditor = a.id_auditor 
                AND TO_CHAR(au.fin_auditoria, 'YYYYMM') = :b_fecha
            ) THEN a.id_auditor END) AS total_con_auditorias,
            COUNT(DISTINCT CASE WHEN NOT EXISTS (
                SELECT 1 FROM auditoria au 
                WHERE au.id_auditor = a.id_auditor 
                AND TO_CHAR(au.fin_auditoria, 'YYYYMM') = :b_fecha
            ) THEN a.id_auditor END) AS total_sin_auditorias,
            NVL(SUM(au.monto_auditoria), 0) AS monto_total_auditorias,
            NVL(SUM(d.total_comision_audit), 0) AS monto_total_comisiones
        FROM
            auditor a
            JOIN profesion p ON a.cod_profesion = p.cod_profesion
            LEFT JOIN auditoria au ON a.id_auditor = au.id_auditor 
                AND TO_CHAR(au.fin_auditoria, 'YYYYMM') = :b_fecha
            LEFT JOIN DETALLE_COMISIONES_AUDITORIAS_MES d ON a.numrun = d.run_auditor
                AND d.mes_proceso = v_mes_proceso AND d.anno_proceso = v_anno_proceso
        GROUP BY
            p.nombre_profesion;
    EXCEPTION
        WHEN OTHERS THEN
            v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
            v_error_stmt := 'INSERT RESUMEN_COMISIONES';
            v_error_msg := SQLERRM;
            INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
    END;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
        v_error_stmt := 'Bloque principal';
        v_error_msg := SQLERRM;
        INSERT INTO ERROR_PROCESO VALUES (v_correlativo, v_error_stmt, v_error_msg);
        COMMIT;
END;
/