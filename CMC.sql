
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

-- variables ESCALARES

v_comision_total_audit NUMBER(10,2);
v_comision_monto_audit NUMBER(10,2);
v_comision_prof_critica NUMBER(10,2);
v_comision_extra NUMBER(10,2);
v_total_comision_audit NUMBER(10,2);
v_total_comision_empresa NUMBER(10,2);




BEGIN
  -- TRUNCA TABLAS
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';

------PRIMER LOOP

FOR reg_auditor IN cur_auditor LOOP 



-- Se inicializan las variables totalizadoras en cero  
v_res_total_auditores  := 0;
v_res_total_con_auditorias    := 0;
v_res_total_sin_auditorias    := 0;
v_res_monto_total_auditorias  := 0;
v_res_monto_total_comisiones := 0;

-----SEGUNDO LOOP


    FOR reg_auditorias IN cur_auditorias(reg_auditor.id_auditor, TO_NUMBER(:p_mes_proceso), TO_NUMBER(:p_anno_proceso)
    ) LOOP

    
--------CALCULOS

----CALCULO POR CANTIDAD DE AUDITORIAS
v_comision_cant_audit := calcular_comision_cant_auditorias(
    reg_auditor.id_auditor,
    reg_auditor.sueldo,
    :b_fecha
);

----CALCULO POR MONTO DE AUDITORIAS
v_comision_monto_audit := calcular_comision_monto_auditado(
    reg_auditor.id_auditor,
    :b_fecha
);

----CALCULO POR PROFESION CRITICA

v_comision_prof_critica:= calcular_comision_prof_crit(
    reg_auditor.id_auditor,
    reg_auditor.sueldo,
    reg_auditor.cod_profesion,
    :b_fecha
);

-----CALCULO POR MONTO EXTRA

v_comision_extra:= calcular_comision_extra(
    reg_auditor.sueldo,
    reg_auditor.cod_tpcontrato
);

-----TOTAL DE COMISIONES

v_total_comision_audit := v_comision_cant_audit + v_comision_monto_audit + v_comision_prof_critica + v_comision_extra;


-----TOTAL EMPRESA



 -- INSERTAR DATOS EN LA TABLA DE DETALLE
INSERT INTO detalle_comisiones_auditorias_mes (
    mes_proceso,
    anno_proceso,
    run_auditor,
    nombre_auditor,
    nombre_profesion,
    comision_total_audit,
    comision_monto_audit,
    comision_prof_critica,
    comision_extra,
    total_comision_audit,
    total_comision_empresa
)
VALUES (
    SUBSTR(:b_fecha,-2),
    SUBSTR(:b_fecha,1,4),
    reg_auditor.numrun || '-' || reg_auditor.dvrun,
    reg_auditor.nombre || ' ' || reg_auditor.appaterno || ' ' || reg_auditor.apmaterno,
    (SELECT nombre_profesion FROM profesion WHERE cod_profesion = reg_auditor.cod_profesion),
    v_comision_cant_audit,
    v_comision_monto_audit,
    v_comision_prof_critica,
    v_comision_extra,
    v_total_comision_audit,
    v_total_comision_empresa
);

-----CALCULO DE LAS VARIABLES TOTALIZADORAS  


END LOOP;

 -- INSERTAR DATOS EN LA TABLA DE RESUMEN
    INSERT INTO resumen_comisiones_auditorias_mes (
    mes_proceso,
    anno_proceso,
    nombre_profesion,
    total_auditores,
    total_con_auditorias,
    total_sin_auditorias,
    monto_total_auditorias,
    monto_total_comisiones
)
VALUES (
    SUBSTR(:b_fecha,-2),
    SUBSTR(:b_fecha,1,4),
    (SELECT nombre_profesion FROM profesion WHERE cod_profesion = reg_auditor.cod_profesion), 
    v_res_total_auditores,
    v_res_total_con_auditorias,
    v_res_total_sin_auditorias,
    v_res_monto_total_auditorias,
    v_res_monto_total_comisiones
);

END LOOP;
COMMIT;
END;  