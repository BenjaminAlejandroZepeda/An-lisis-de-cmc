--Ahora sí que van las funciones ajsjs

DROP FUNCTION FN_COMISION_TOTAL_AUDIT;
DROP FUNCTION FN_COMISION_MONTO_AUDIT;
DROP FUNCTION FN_COMISION_PROF_CRITICA;
DROP FUNCTION FN_COMISION_EXTRA;
DROP FUNCTION FN_TOTAL_COMISION_AUDIT;

-- [10-40]
CREATE OR REPLACE FUNCTION FN_COMISION_TOTAL_AUDIT(id_aud IN NUMBER, a_sueldo IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_total_auditorias  NUMBER(5);
    v_porc_total_audit  NUMBER(4,2);
    v_comision          NUMBER(10,2);
BEGIN
    SELECT COUNT(*) 
    INTO v_total_auditorias
    FROM auditoria a
    WHERE a.id_auditor = id_aud AND TO_CHAR(a.inicio_auditoria, 'YYYYMM') = fecha_proceso;

    IF v_total_auditorias = 0 THEN
        RETURN 0;
    END IF;

    SELECT pt.porc_total_audit
    INTO v_porc_total_audit
    FROM porc_total_auditorias pt
    WHERE v_total_auditorias BETWEEN pt.total_audit_min AND pt.total_audit_max;

    v_comision := (a_sueldo * v_porc_total_audit) / 100;
    RETURN ROUND(v_comision, 2);
    
EXCEPTION        
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
        
END FN_COMISION_TOTAL_AUDIT;

--[43-72]
CREATE OR REPLACE FUNCTION FN_COMISION_MONTO_AUDIT(id_aud IN NUMBER, fecha_proceso IN VARCHAR2) 
RETURN NUMBER 
IS
    v_total_monto_audit  NUMBER(10);
    v_porc_monto_audit   NUMBER(4,2);
    v_comision           NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(a.monto_auditoria), 0) 
    INTO v_total_monto_audit
    FROM auditoria a
    WHERE a.id_auditor = id_aud AND TO_CHAR(a.inicio_auditoria, 'YYYYMM') = fecha_proceso;
    
    IF v_total_monto_audit > 0 THEN
        SELECT pm.porc_monto_audit
        INTO v_porc_monto_audit
        FROM porc_monto_auditorias pm
        WHERE v_total_monto_audit BETWEEN pm.monto_audit_min AND pm.monto_audit_max;
        v_comision := v_total_monto_audit * v_porc_monto_audit;
        RETURN ROUND(v_comision, 2);
    ELSE
        RETURN 0;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
        
END FN_COMISION_MONTO_AUDIT;

--[75-99]
CREATE OR REPLACE FUNCTION FN_COMISION_PROF_CRITICA(a_sueldo IN NUMBER, cod_profesion IN NUMBER)
RETURN NUMBER
IS
    v_nivel_criticidad  NUMBER;
    v_comision          NUMBER(10,2);
BEGIN
    SELECT p.nivel_criticidad
    INTO v_nivel_criticidad
    FROM profesion p
    WHERE p.id_profesion = cod_profesion;
    
    IF v_nivel_criticidad >= 3 THEN
        v_comision := a_sueldo * 0.05;
        RETURN ROUND(v_comision, 2);
    ELSE
        RETURN 0;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
        
END FN_COMISION_PROF_CRITICA;

--[102-121]
CREATE OR REPLACE FUNCTION FN_COMISION_EXTRA(a_sueldo IN NUMBER, a_tipo_contrato IN NUMBER)
RETURN NUMBER
IS
    v_porc_incentivo  NUMBER(5,2);
    v_comision        NUMBER(10,2);
BEGIN
    SELECT tc.porc_incentivo
    INTO v_porc_incentivo
    FROM tipo_contrato tc
    WHERE tc.id_tipo_contrato = a_tipo_contrato;
    v_comision := a_sueldo * (v_porc_incentivo / 100);
    RETURN ROUND(v_comision, 2);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
        
END FN_COMISION_EXTRA;

--[124-139]
CREATE OR REPLACE FUNCTION FN_TOTAL_COMISION_AUDIT(id_aud IN NUMBER, a_sueldo IN NUMBER, fecha_proceso IN VARCHAR2, cod_profesion IN NUMBER, a_tipo_contrato IN NUMBER)
RETURN NUMBER
IS
BEGIN
    RETURN ROUND(
        NVL(FN_COMISION_TOTAL_AUDIT(id_aud, a_sueldo, fecha_proceso), 0) +
        NVL(FN_COMISION_MONTO_AUDIT(id_aud, fecha_proceso), 0) +
        NVL(FN_COMISION_PROF_CRITICA(a_sueldo, cod_profesion), 0) +
        NVL(FN_COMISION_EXTRA(a_sueldo, a_tipo_contrato), 0),
        2
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
        
END FN_TOTAL_COMISION_AUDIT;