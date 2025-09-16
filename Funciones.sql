--IMPORTANTE: EJECUTAR CADA BLOQUE POR SEPARADO
--Recomiendo que la fecha de proceso en la variable bind encapsule mes y año bajo un formato 'YYYYMM'
DROP FUNCTION calcular_comision_cant_auditorias;
DROP FUNCTION calcular_comision_monto_auditado;
DROP FUNCTION calcular_comision_prof_crit;
DROP FUNCTION calcular_comision_extra;
DROP FUNCTION calcular_comision_total;

--REGLA DE NEGOCIO 1.1 [10-33]
CREATE FUNCTION calcular_comision_cant_auditorias(id_aud IN NUMBER, a_sueldo IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_total_auditorias  NUMBER(5);
    v_porc_total_audit  NUMBER(4,2);
    v_comision          NUMBER(10,2);
BEGIN
    SELECT NVL(COUNT(a.monto_auditoria),0) 
    INTO v_total_auditorias
    FROM auditoria a
    WHERE a.id_auditor = id_aud AND TO_CHAR(a.inicio_auditoria, 'YYYYMM') = fecha_proceso;
    
    SELECT pt.porc_total_audit
    INTO v_porc_total_audit
    FROM porc_total_auditorias pt
    WHERE v_total_auditorias BETWEEN pt.total_audit_min AND pt.total_audit_max;

    v_comision := (a_sueldo * v_porc_total_audit) / 100;
    RETURN ROUND(v_comision,2);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  
END calcular_comision_cant_auditorias;

--REGLA DE NEGOCIO 1.2 [36-59]
CREATE FUNCTION calcular_comision_monto_auditado(id_aud IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_total_monto_audit  NUMBER(10);
    v_porc_monto_audit   NUMBER(4,2);
    v_comision           NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(a.monto_auditoria),0) 
    INTO v_total_monto_audit
    FROM auditoria a
    WHERE a.id_auditor = id_aud AND TO_CHAR(a.inicio_auditoria, 'YYYYMM') = fecha_proceso;
    
    SELECT pm.porc_monto_audit
    INTO v_porc_monto_audit
    FROM porc_monto_auditorias pm
    WHERE v_total_monto_audit BETWEEN pm.monto_audit_min AND pm.monto_audit_max;
    
    v_comision:=v_total_monto_audit*v_porc_monto_audit;
    RETURN ROUND(v_comision,2);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END calcular_comision_monto_auditado;

--REGLA DE NEGOCIO 1.3 [62-77]
CREATE FUNCTION calcular_comision_prof_crit(a_sueldo IN NUMBER, cod_profesion IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_comision      NUMBER(10,2);
BEGIN
    IF(cod_profesion>=3)THEN
        v_comision:=a_sueldo*0.05;
        RETURN ROUND(v_comision,2);
    ELSE
        v_comision:=0;
        RETURN v_comision;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END calcular_comision_prof_crit;

--REGLA DE NEGOCIO 1.4 [80-97]
CREATE FUNCTION calcular_comision_extra(a_sueldo IN NUMBER, a_tipo_contrato IN NUMBER)
RETURN NUMBER
IS
    v_porc_incentivo    NUMBER(10,2);
    v_comision          NUMBER(10,2);
BEGIN
    SELECT
        tp.porc_incentivo
    INTO v_porc_incentivo
    FROM tipo_contrato tp
    WHERE a_tipo_contrato=tp.cod_tpcontrato;
    
    v_comision:= (a_sueldo * v_porc_incentivo)/100;
    RETURN ROUND(v_comision,2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END calcular_comision_extra;

--REGLA DE NEGOCIO 1.5 [100-118]
CREATE FUNCTION calcular_comision_total(id_aud IN NUMBER, a_tipo_contrato IN NUMBER, cod_profesion IN NUMBER, a_sueldo IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_com_cant_aud      NUMBER(10,2);
    v_com_mon_aud       NUMBER(10,2);
    v_com_prof_crit     NUMBER(10,2);
    v_com_extra         NUMBER(10,2);
    v_comision          NUMBER(10,2);
BEGIN
    v_com_cant_aud:=calcular_comision_cant_auditorias(id_aud, a_sueldo, fecha_proceso);
    v_com_mon_aud:=calcular_comision_monto_auditado(id_aud, fecha_proceso);
    v_com_prof_crit:=calcular_comision_prof_crit(a_sueldo, cod_profesion, fecha_proceso);
    v_com_extra:=calcular_comision_extra(a_sueldo, a_tipo_contrato);
    v_comision:= v_com_cant_aud + v_com_mon_aud + v_com_prof_crit + v_com_extra;
    RETURN ROUND(v_comision,2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END calcular_comision_total;
