-----VARIABLES BIND
VARIABLE b_fecha VARCHAR2(6);
EXEC :b_fecha := '202301';

VARIABLE p_valor_limite_com NUMBER;
EXEC :p_valor_limite_com := 500000;

DECLARE 
----- Variables para mes y a�o
    v_mes_proceso  NUMBER(2);
    v_anno_proceso NUMBER(4);
    v_correlativo  NUMBER := 0;

-----CURSOR SIN PARAMETROS
    CURSOR cur_auditor IS
    SELECT
        a.id_auditor,
        a.numrun,
        a.nombre,
        a.sueldo,
        a.cod_profesion,
        a.cod_tpcontrato,
        p.nombre_profesion,
        p.nivel_criticidad
    FROM
        auditor a
        JOIN profesion p ON a.cod_profesion = p.cod_profesion;


-----CURSOR CON PARAMETROS
    CURSOR cur_empresas (p_id_auditor NUMBER,p_fecha_proceso VARCHAR2) IS
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

-----Variables Escalares
    v_comision_cant_audit    NUMBER(10, 2);
    v_comision_monto_audit   NUMBER(10, 2);
    v_comision_prof_critica  NUMBER(10, 2);
    v_comision_extra         NUMBER(10, 2);
    v_total_comision_audit   NUMBER(10, 2);
    v_total_comision_empresa NUMBER(10, 2);
    v_total_auditor          NUMBER(10, 2);
    
    
-----VARRAY
      TYPE tipo_varray_porc_inc IS VARRAY(4) OF NUMBER(5,2);
        varray_porc_inc tipo_varray_porc_inc;
    
    
BEGIN
-- Truncar tablas
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';
    EXECUTE IMMEDIATE 'DROP SEQUENCE SQ_ERROR';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE SQ_ERROR';
-- Extraer mes y a�o de :b_fecha
    v_anno_proceso := TO_NUMBER(SUBSTR(:b_fecha, 1, 4));
    v_mes_proceso  := TO_NUMBER(SUBSTR(:b_fecha, -2));
    
    varray_porc_inc := tipo_varray_porc_inc(15.00, 10.00, 5.00, 5.00);

-- Primer LOOP
    FOR reg_auditor IN cur_auditor LOOP
        -- Inicializar variables
        v_comision_cant_audit    := 0;
        v_comision_monto_audit   := 0;
        v_comision_prof_critica  := 0;
        v_comision_extra         := 0;
        v_total_comision_audit   := 0;
        v_total_comision_empresa := 0;
        v_total_auditor          := 0;

-- Segundo LOOP
        FOR reg_emp IN cur_empresas(reg_auditor.id_auditor, :b_fecha) LOOP
-----CANTIDAD DE AUDITORIAS            



----MONTO POR AUDITORIAS

----CALCULO POR PROFESION CRITICA

-----MONTO EXTRA

-----TOTAL

v_total_comision_audit := v_comision_cant_audit+ v_comision_monto_audit+ v_comision_prof_critica+ v_comision_extra;

-----TOTAL EMPRESA



-- Insertar en la tabla detalle
                INSERT INTO DETALLE_COMISIONES_AUDITORIAS_MES (
                    MES_PROCESO,
                    ANNO_PROCESO,
                    RUN_AUDITOR,
                    NOMBRE_AUDITOR,
                    NOMBRE_PROFESION,
                    COMISION_TOTAL_AUDIT,
                    COMISION_MONTO_AUDIT,
                    COMISION_PROF_CRITICA,
                    COMISION_EXTRA,
                    TOTAL_COMISION_AUDIT,
                    TOTAL_COMISION_EMPRESA,
                    COD_EMPRESA
                ) VALUES (
                    v_mes_proceso,
                    v_anno_proceso,
                    reg_auditor.numrun,
                    reg_auditor.nombre,
                    reg_auditor.nombre_profesion,
                    v_comision_cant_audit,
                    v_comision_monto_audit,
                    v_comision_prof_critica,
                    v_comision_extra,
                    v_total_comision_audit,
                    v_total_comision_empresa,
                    reg_emp.cod_empresa
                );
                
-----CALCULO DE LAS VARIABLES TOTALIZADORAS                  
                
                
                
                
        END LOOP;
    -- Resumen por profesi�n (usar funci�n con cod_empresa = NULL para total por auditor)
    INSERT INTO RESUMEN_COMISIONES_AUDITORIAS_MES (
        MES_PROCESO,
        ANNO_PROCESO,
        NOMBRE_PROFESION,
        TOTAL_AUDITORES,
        TOTAL_CON_AUDITORIAS,
        TOTAL_SIN_AUDITORIAS,
        MONTO_TOTAL_AUDITORIAS,
        MONTO_TOTAL_COMISIONES
    )
    SELECT
        v_mes_proceso,
        v_anno_proceso,
        p.nombre_profesion,
        COUNT(DISTINCT a.id_auditor) AS total_auditores,
        COUNT(DISTINCT CASE WHEN au.id_auditor IS NOT NULL THEN a.id_auditor END) AS total_con_auditorias,
        COUNT(DISTINCT CASE WHEN au.id_auditor IS NULL THEN a.id_auditor END) AS total_sin_auditorias,
        NVL(SUM(au.monto_auditoria), 0) AS monto_total_auditorias,
        NVL(SUM(
            calcular_comision_cant_auditorias(a.id_auditor, NULL, a.sueldo, :b_fecha) +
            calcular_comision_monto_auditado(a.id_auditor, :b_fecha) +
            calcular_comision_prof_crit(a.sueldo, p.nivel_criticidad) +
            calcular_comision_extra(a.sueldo, a.cod_tpcontrato)
        ), 0) AS monto_total_comisiones
    FROM
        auditor a
        JOIN profesion p ON a.cod_profesion = p.cod_profesion
        LEFT JOIN auditoria au ON a.id_auditor = au.id_auditor 
            AND TO_CHAR(au.fin_auditoria, 'YYYYMM') = :b_fecha
    GROUP BY
        p.nombre_profesion;
        
END LOOP;
COMMIT;
END;  
/
