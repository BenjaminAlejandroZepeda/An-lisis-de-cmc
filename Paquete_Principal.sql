

Drop sequence SEQ_ERROR_PROCESO;

CREATE SEQUENCE SEQ_ERROR_PROCESO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE PACKAGE PKG_COMISIONES_AUDITORIA IS
  PROCEDURE PRC_CALCULAR_COMISION_AUDITOR(p_id_auditor IN NUMBER, p_fecha_proceso IN VARCHAR2);
END PKG_COMISIONES_AUDITORIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_COMISIONES_AUDITORIA IS

  PROCEDURE PRC_CALCULAR_COMISION_AUDITOR(p_id_auditor IN NUMBER, p_fecha_proceso IN VARCHAR2) IS
      -- Variables principales
      v_sueldo NUMBER(8);
      v_cod_profesion NUMBER;
      v_tipo_contrato auditor.cod_tpcontrato%TYPE;
      v_run VARCHAR2(15);
      v_nombre VARCHAR2(70);
      v_nombre_profesion VARCHAR2(30);
      v_mes_proceso NUMBER(6);
      v_anno_proceso NUMBER(6);

      -- Cálculos
      v_comision_cantidad NUMBER(10,2);
      v_comision_monto NUMBER(10,2);
      v_comision_prof_critica NUMBER(10,2);
      v_comision_extra NUMBER(10,2);
      v_total_comision_auditor NUMBER(10,2);
      v_monto_total_auditor NUMBER(15,2);
      v_comision_empresa NUMBER(10,2);

      -- Error
      v_correlativo NUMBER;
      v_auditor_info VARCHAR2(200);
      v_mensaje_error VARCHAR2(400);

      -- Cursor auditorías
      CURSOR c_auditorias IS
          SELECT a.cod_empresa AS cod_empresa, SUM(a.monto_auditoria) AS monto_empresa
          FROM auditoria a
          WHERE a.id_auditor = p_id_auditor 
            AND TO_CHAR(a.fin_auditoria,'YYYYMM') = p_fecha_proceso
          GROUP BY a.cod_empresa;

      v_count_auditorias NUMBER;

  BEGIN
      -- Limpiar tablas
      EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';

      -- Obtener datos del auditor
      BEGIN
          SELECT 
              a.numrun || '-' || a.dvrun,
              a.nombre || ' ' || a.appaterno || ' ' || a.apmaterno,
              a.sueldo,
              a.cod_profesion,
              a.cod_tpcontrato,
              p.nombre_profesion
          INTO 
              v_run, v_nombre, v_sueldo, v_cod_profesion, v_tipo_contrato, v_nombre_profesion
          FROM auditor a
          JOIN profesion p ON a.cod_profesion = p.cod_profesion
          WHERE a.id_auditor = p_id_auditor;

          v_auditor_info := 'Auditor: ' || p_id_auditor || ' Run: ' || v_run || ' - Nombre: ' || v_nombre;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              SELECT SEQ_ERROR_PROCESO.NEXTVAL INTO v_correlativo FROM dual;
              v_mensaje_error := 'Auditor no encontrado: ' || p_id_auditor;
              INSERT INTO ERROR_PROCESO(correlativo, sentencia_error, mensaje_error) 
              VALUES (v_correlativo,'PRC_CALCULAR_COMISION_AUDITOR', v_mensaje_error);
              RETURN;
      END;

      -- Contar auditorías
      SELECT COUNT(*) INTO v_count_auditorias
      FROM auditoria a
      WHERE a.id_auditor = p_id_auditor 
        AND TO_CHAR(a.fin_auditoria,'YYYYMM') = p_fecha_proceso;

      IF v_count_auditorias = 0 THEN
          SELECT SEQ_ERROR_PROCESO.NEXTVAL INTO v_correlativo FROM dual;
          v_mensaje_error := v_auditor_info || ' - No tiene auditorías finalizadas en ' || p_fecha_proceso;
          INSERT INTO ERROR_PROCESO(correlativo, sentencia_error, mensaje_error)
          VALUES (v_correlativo,'PRC_CALCULAR_COMISION_AUDITOR', v_mensaje_error);
          RETURN;
      END IF;

      -- Extraer mes/año
      SELECT TO_NUMBER(TO_CHAR(a.fin_auditoria,'MM')),
             TO_NUMBER(TO_CHAR(a.fin_auditoria,'YYYY'))
      INTO v_mes_proceso, v_anno_proceso
      FROM auditoria a
      WHERE a.id_auditor = p_id_auditor 
        AND TO_CHAR(a.fin_auditoria,'YYYYMM') = p_fecha_proceso 
        AND ROWNUM = 1;

      -- Llamadas a funciones del otro package
      v_comision_cantidad     := PKG_FUNCIONES_COMISION.FN_COMISION_TOTAL_AUDIT(p_id_auditor, v_sueldo, p_fecha_proceso);
      v_comision_monto        := PKG_FUNCIONES_COMISION.FN_COMISION_MONTO_AUDIT(p_id_auditor, p_fecha_proceso);
      v_comision_prof_critica := PKG_FUNCIONES_COMISION.FN_COMISION_PROF_CRITICA(v_sueldo, v_cod_profesion);
      v_comision_extra        := PKG_FUNCIONES_COMISION.FN_COMISION_EXTRA(v_sueldo, v_tipo_contrato);
      v_total_comision_auditor := PKG_FUNCIONES_COMISION.FN_TOTAL_COMISION_AUDIT(
          p_id_auditor, v_sueldo, p_fecha_proceso, v_cod_profesion, v_tipo_contrato
      );

      SELECT NVL(SUM(a.monto_auditoria),0)
      INTO v_monto_total_auditor
      FROM auditoria a
      WHERE a.id_auditor = p_id_auditor 
        AND TO_CHAR(a.fin_auditoria,'YYYYMM') = p_fecha_proceso;

      -- Procesar distribución por empresa
      FOR reg_empresa IN c_auditorias LOOP
          DECLARE
              v_cod_empresa NUMBER := reg_empresa.cod_empresa;
              v_monto_empresa NUMBER := reg_empresa.monto_empresa;
          BEGIN
              IF v_monto_total_auditor > 0 THEN
                  v_comision_empresa := v_total_comision_auditor * (v_monto_empresa / v_monto_total_auditor);
              ELSE
                  v_comision_empresa := 0;
              END IF;

              INSERT INTO DETALLE_COMISIONES_AUDITORIAS_MES (
                  mes_proceso, anno_proceso, run_auditor, nombre_auditor, nombre_profesion,
                  comision_total_audit, comision_monto_audit, comision_prof_critica, comision_extra,
                  total_comision_audit, total_comision_empresa, cod_empresa
              ) VALUES (
                  v_mes_proceso, v_anno_proceso, v_run, v_nombre, v_nombre_profesion,
                  v_comision_cantidad, v_comision_monto, v_comision_prof_critica, v_comision_extra,
                  v_total_comision_auditor, v_comision_empresa, v_cod_empresa
              );
          END;
      END LOOP;

      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
          SELECT SEQ_ERROR_PROCESO.NEXTVAL INTO v_correlativo FROM dual;
          v_mensaje_error := v_auditor_info || ' - Error general: ' || SQLERRM;
          INSERT INTO ERROR_PROCESO(correlativo, sentencia_error, mensaje_error) 
          VALUES (v_correlativo,'PRC_CALCULAR_COMISION_AUDITOR', v_mensaje_error);
  END PRC_CALCULAR_COMISION_AUDITOR;

END PKG_COMISIONES_AUDITORIA;
/
