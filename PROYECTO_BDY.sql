--VARIABLES BIND

VARIABLE p_fecha_proceso VARCHAR2(6);
EXEC :p_fecha_proceso := '202301';     --FECHA EN FORMATO YYYYMM

VARIABLE p_valor_limite_com NUMBER;
EXEC :p_valor_limite_com := 500000;

DECLARE 
----CURSOR SIN PARAMETROS
    CURSOR cur_auditor IS
        SELECT 
            id_auditor AS id, 
            numrun AS run,
            dvrun AS dv, 
            nombre ||' '|| appaterno ||' '|| apmaterno AS nombre, 
            sueldo AS sueldo, 
            cod_profesion AS codigoProfesion, 
            cod_tpcontrato AS codigoTipoContrato
        FROM auditor
        ORDER BY id_auditor;

----CURSOR CON PARAMETROS  
    CURSOR cur_auditorias(p_id_auditor NUMBER) IS
        SELECT 
            a.cod_empresa AS codigoEmpresa, 
            a.monto_auditoria AS montoAuditoria, 
            a.fin_auditoria AS finAuditoria
        FROM auditoria a
        WHERE a.id_auditor = p_id_auditor
        AND EXTRACT(MONTH FROM a.fin_auditoria) = p_mes_proceso
        AND EXTRACT(YEAR FROM a.fin_auditoria) = p_anno_proceso;

----VARIABLES ESCALARES
    v_comision_total_audit NUMBER(10,2);
    v_comision_monto_audit NUMBER(10,2);
    v_comision_prof_critica NUMBER(10,2);
    v_comision_extra NUMBER(10,2);
    
----VARIABLES TOTALIZADORAS
    v_total_monto NUMBER(10,2);
    v_total_auditorias NUMBER;
    v_total_comision_audit NUMBER(10,2);
    v_total_comision_empresa NUMBER(10,2);
    
----VARRAY
    TYPE tipo_varray_porc_inc IS VARRAY(5) OF NUMBER;
    varray_porc_inc tipo_varray_porc_inc;

BEGIN
----TRUNCAR TABLAS
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_COMISIONES_AUDITORIAS_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERROR_PROCESO';
    varray_porc_inc:= tipo_varray_porc_inc(0.05,0.05,0.10,0.15);

----PRIMER LOOP
    FOR reg_auditor IN cur_auditor LOOP 
--------INICIALIZACIÓN DE LAS VARIABLES TOTALIZADORAS EN 0 
        v_total_monto := 0;
        v_total_auditorias := 0;
        v_total_comision_audit := 0;
        v_total_comision_empresa := 0;
        
--------SEGUNDO LOOP
        FOR reg_auditorias IN cur_auditorias(reg_auditor.id) LOOP
------------CÁLCULOS
            SELECT NVL(COUNT(a.monto_auditoria),0) 
            INTO v_total_auditorias
            FROM auditoria a
            WHERE a.id_auditor=reg_profesional.id AND to_char(a.inicio_auditoria, 'YYYYMM') = :p_fecha_proceso;  
    


---- TRIGGER





-----CANTIDAD DE AUDITORIAS

----MONTO POR AUDITORIAS

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