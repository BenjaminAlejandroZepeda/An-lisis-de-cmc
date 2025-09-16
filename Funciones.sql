CREATE OR REPLACE FUNCTION calcular_comision_cant_auditorias(
    p_id_aud       IN NUMBER,
    p_cod_empresa  IN NUMBER,      -- puede venir NULL para total del auditor
    p_sueldo       IN NUMBER,
    p_fecha_proc   IN VARCHAR2
) RETURN NUMBER IS
    v_total_auditorias  NUMBER(10);
    v_porc_total_audit  NUMBER(5,2);
    v_comision          NUMBER(12,2);
BEGIN
    SELECT COUNT(*)
    INTO v_total_auditorias
    FROM auditoria
    WHERE id_auditor = p_id_aud
      AND TO_CHAR(fin_auditoria, 'YYYYMM') = p_fecha_proc
      AND (p_cod_empresa IS NULL OR cod_empresa = p_cod_empresa);

    SELECT porc_total_audit
    INTO v_porc_total_audit
    FROM porc_total_auditorias
    WHERE v_total_auditorias BETWEEN total_audit_min AND total_audit_max
      AND ROWNUM = 1;

    v_comision := (p_sueldo * v_porc_total_audit) / 100;
    RETURN ROUND(v_comision, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;


-- Función para comisión por monto auditado (corregida)
CREATE OR REPLACE FUNCTION calcular_comision_monto_auditado(id_aud IN NUMBER, fecha_proceso IN VARCHAR2)
RETURN NUMBER
IS
    v_total_monto_audit  NUMBER(10);
    v_porc_monto_audit   NUMBER(4,2);
    v_comision           NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(a.monto_auditoria),0) 
    INTO v_total_monto_audit
    FROM auditoria a
    WHERE a.id_auditor = id_aud AND TO_CHAR(a.fin_auditoria, 'YYYYMM') = fecha_proceso;
    
    -- Modificación: Usar ROWNUM para tomar solo una fila en caso de múltiples coincidencias
    SELECT porc_monto_audit
    INTO v_porc_monto_audit
    FROM porc_monto_auditorias
    WHERE v_total_monto_audit BETWEEN monto_audit_min AND monto_audit_max
      AND ROWNUM = 1; -- Tomamos la primera fila que cumpla la condición

    v_comision := v_total_monto_audit * v_porc_monto_audit;
    RETURN ROUND(v_comision,2);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END calcular_comision_monto_auditado;
/

-- Función para comisión por profesión crítica (corregida)
CREATE OR REPLACE FUNCTION calcular_comision_prof_crit(
    a_sueldo IN NUMBER, 
    nivel_criticidad IN NUMBER
) RETURN NUMBER IS
BEGIN
    IF nivel_criticidad >= 3 THEN
        RETURN ROUND(a_sueldo * 0.05, 2);
    ELSE
        RETURN 0;
    END IF;
END;
/

--REGLA DE NEGOCIO 1.4 [74-91]
CREATE OR REPLACE FUNCTION calcular_comision_extra (
  a_sueldo IN NUMBER,
  a_tipo_contrato IN NUMBER
) RETURN NUMBER IS

  TYPE tipo_varray_porc_inc IS VARRAY(4) OF NUMBER(5,2);
  varray_porc_inc tipo_varray_porc_inc := tipo_varray_porc_inc(15.00, 10.00, 5.00, 5.00);
  v_comision NUMBER(10,2);
BEGIN

  -- Validar que el tipo de contrato est� dentro del rango v�lido 1-4
  IF a_tipo_contrato BETWEEN 1 AND 4 THEN
    v_comision := a_sueldo * (varray_porc_inc(a_tipo_contrato) / 100);
  ELSE
    v_comision := 0;
  END IF;
  RETURN ROUND(v_comision, 2);

EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END calcular_comision_extra;

/