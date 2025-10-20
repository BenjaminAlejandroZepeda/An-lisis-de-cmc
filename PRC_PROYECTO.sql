CREATE OR REPLACE PROCEDURE PRC_CALCULAR_COMISION_AUDITOR(p_id_auditor IN NUMBER, p_fecha_proceso IN VARCHAR2)
IS
    -- Datos auditor        %TYPE facilita la compatibilidad de tipos
    v_sueldo                NUMBER(8);
    v_cod_profesion         NUMBER;
    v_tipo_contrato         auditor.cod_tpcontrato%TYPE;
    v_run                   VARCHAR2(15);
    v_nombre                VARCHAR2(70);
    v_nombre_profesion      VARCHAR2(30);
    v_mes_proceso           NUMBER(6);
    v_anno_proceso          NUMBER(6);
    v_cod_empresa           NUMBER(5);
    
    -- Cálculos
    v_comision_cantidad         NUMBER(10,2);
    v_comision_monto            NUMBER(10,2);
    v_comision_prof_critica     NUMBER(10,2);
    v_comision_extra            NUMBER(10,2);
    v_total_comision_auditor    NUMBER(10,2);
    v_monto_total_auditor       NUMBER(15,2);
    v_comision_empresa          NUMBER(10,2);
    
    -- Error
    v_correlativo               NUMBER;
    v_auditor_info              VARCHAR2(200);
    
    -- Cursor auditorías
    CURSOR c_auditorias IS
        SELECT a.cod_empresa, SUM(a.monto_auditoria) as monto_empresa
        FROM auditoria a
        WHERE a.id_auditor = p_id_auditor AND TO_CHAR(a.fin_auditoria, 'YYYYMM') = p_fecha_proceso
        GROUP BY a.cod_empresa;
        
    v_count_auditorias          NUMBER;
    
BEGIN
    -- TRUNCATE
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';
    
    -- Reinicio SEQUENCE
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ERROR_PROCESO';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_ERROR_PROCESO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    
    -- Datos auditor
    BEGIN
        SELECT a.numrun||'-'||a.dvrun, a.nombre||' '||a.appaterno||' '||a.apmaterno, a.sueldo, a.cod_profesion, a.cod_tpcontrato, p.nombre_profesion, e.cod_empresa
        INTO v_run, v_nombre, v_sueldo, v_cod_profesion, v_tipo_contrato, v_nombre_profesion, v_cod_empresa
        FROM auditor a
        JOIN profesion p ON a.cod_profesion = p.cod_profesion
        JOIN comuna c ON a.cod_comuna = c.cod_comuna
        JOIN empresa e ON c.cod_comuna = e.cod_comuna
        WHERE a.id_auditor = p_id_auditor;
        
        v_auditor_info := 'Auditor: ' || p_id_auditor || ' Run: - ' || v_run || ' - Nombre: ' || v_nombre;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
            INSERT INTO ERROR_PROCESO VALUES (v_correlativo, 'PRC_CALCULAR_COMISION_AUDITOR', 
                    'Auditor no encontrado: ' || p_id_auditor);
            RETURN;
    END;
    
    -- Auditorías finalizadas (val)
    SELECT COUNT(*) INTO v_count_auditorias
    FROM auditoria a
    WHERE a.id_auditor = p_id_auditor AND TO_CHAR(a.fin_auditoria, 'YYYYMM') = p_fecha_proceso;
    
    IF v_count_auditorias = 0 THEN
        v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
        INSERT INTO ERROR_PROCESO VALUES (v_correlativo, 'PRC_CALCULAR_COMISION_AUDITOR', 
                v_auditor_info || ' - No tiene auditorías finalizadas en ' || p_fecha_proceso);
        RETURN;
    END IF;
    
    SELECT TO_NUMBER(TO_CHAR(a.fin_auditoria, 'MM')), TO_NUMBER(TO_CHAR(a.fin_auditoria, 'YYYY'))
    INTO v_mes_proceso, v_anno_proceso
    FROM auditoria a
    WHERE a.id_auditor = p_id_auditor AND TO_CHAR(a.fin_auditoria, 'YYYYMM') = p_fecha_proceso AND ROWNUM = 1;
    
    -- Cálculo comisiones
    v_comision_cantidad := FN_COMISION_TOTAL_AUDIT(p_id_auditor, v_sueldo, p_fecha_proceso);
    v_comision_monto := FN_COMISION_MONTO_AUDIT(p_id_auditor, p_fecha_proceso);
    v_comision_prof_critica := FN_COMISION_PROF_CRITICA(v_sueldo, v_cod_profesion);
    v_comision_extra := FN_COMISION_EXTRA(v_sueldo, v_tipo_contrato);
    
    -- Cálculo total
    v_total_comision_auditor := FN_TOTAL_COMISION_AUDIT(
        p_id_auditor, v_sueldo, p_fecha_proceso, v_cod_profesion, v_tipo_contrato
    );
    
    SELECT NVL(SUM(a.monto_auditoria), 0)
    INTO v_monto_total_auditor
    FROM auditoria a
    WHERE a.id_auditor = p_id_auditor AND TO_CHAR(a.fin_auditoria, 'YYYYMM') = p_fecha_proceso;
    
    -- Procesar distribución por empresa
    FOR reg_empresa IN c_auditorias LOOP
        IF v_monto_total_auditor > 0 THEN
            v_comision_empresa := v_total_comision_auditor * (reg_empresa.monto_empresa / v_monto_total_auditor);
        ELSE
            v_comision_empresa := 0;
        END IF;
        
        INSERT INTO DETALLE_COMISIONES_AUDITORIAS_MES (
            mes_proceso, anno_proceso, 
            run_auditor, nombre_auditor, nombre_profesion,
            comision_total_audit, comision_monto_audit, comision_prof_critica, comision_extra,
            total_comision_audit, total_comision_empresa,
            cod_empresa
        )VALUES(
            v_mes_proceso, v_anno_proceso,
            v_run, v_nombre, v_nombre_profesion,
            v_total_comision_auditor, v_comision_monto, v_comision_prof_critica, v_comision_extra,
            v_monto_total_auditor, v_comision_empresa,
            v_cod_empresa
        );
    END LOOP;
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        v_correlativo := SEQ_ERROR_PROCESO.NEXTVAL;
        INSERT INTO ERROR_PROCESO VALUES (v_correlativo, 'PRC_CALCULAR_COMISION_AUDITOR', v_auditor_info);
        
END PRC_CALCULAR_COMISION_AUDITOR;