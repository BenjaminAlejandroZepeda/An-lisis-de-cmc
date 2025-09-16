
-- VARIABLES BIND


VARIABLE b_fecha VARCHAR2(6);
EXEC :b_fecha := '202301';



VARIABLE p_valor_limite_com NUMBER;
EXEC :p_valor_limite_com := 500000;

DECLARE 

------CURSOR SIN PARAMETROS

CURSOR cur_auditor IS
    SELECT id_auditor, numrun, nombre, sueldo, cod_profesion, cod_tpcontrato
    FROM auditor;


----CURSOR CON PARAMETROS  

CURSOR cur_auditorias(p_id_auditor NUMBER, p_mes_proceso NUMBER, p_anno_proceso NUMBER) IS
    SELECT 
        cod_empresa, monto_auditoria, fin_auditoria
    FROM auditoria
    WHERE id_auditor = p_id_auditor
    AND EXTRACT(MONTH FROM fin_auditoria) = p_mes_proceso
    AND EXTRACT(YEAR FROM fin_auditoria) = p_anno_proceso;

-----ESCALARES
v_cant_auditorias NUMBER(8);
v_monto_auditorias NUMBER(8);

-- variables TOTALIZADORAS

v_comision_total_audit NUMBER(10,2);
v_comision_monto_audit NUMBER(10,2);
v_comision_prof_critica NUMBER(10,2);
v_comision_extra NUMBER(10,2);
v_total_comision_audit NUMBER(10,2);
v_total_comision_empresa NUMBER(10,2);


-----VARRAY
-- Varray TIPO_CONTRATO PORC_INCENTIVO
TYPE tipo_varray_porc_inc IS VARRAY(5)
OF NUMBER;


varray_porc_inc tipo_varray_porc_inc;


BEGIN
  -- TRUNCA TABLAS
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';


  varray_porc_inc:= tipo_varray_porc_inc(0.05,0.05,0.10,0.15);



------PRIMER LOOP

FOR reg_auditor IN cur_auditor LOOP 



-- Se inicializan las variables totalizadoras en cero  
-- variables TOTALIZADORAS
    v_total_monto := 0;
    v_comision_total_audit := 0;
    v_comision_monto_audit := 0;
    v_comision_prof_critica := 0;
    v_comision_extra := 0;
    v_total_comision_audit := 0;
    v_total_comision_empresa := 0;

-----SEGUNDO LOOP


    FOR reg_auditorias IN cur_auditorias(reg_auditor.id_auditor, TO_NUMBER(:p_mes_proceso), TO_NUMBER(:p_anno_proceso)
    ) LOOP

    


--------CALCULOS

v_comision_total_audit := calcular_comision_cant_auditorias(
  reg_auditor.id_auditor,
  reg_auditor.sueldo,
  :b_fecha
);

    

----CALCULO POR PROFESION CRITICA

-----MONTO EXTRA

-----TOTAL

-----TOTAL EMPRESA
  

    END LOOP;

 -- INSERTAR DATOS EN LA TABLA DE DETALLE

-----CALCULO DE LAS VARIABLES TOTALIZADORAS  

END LOOP;

 -- INSERTAR DATOS EN LA TABLA DE RESUMEN

COMMIT;

END;  