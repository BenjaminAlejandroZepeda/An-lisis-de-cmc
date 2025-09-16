--SCRIPT PARA COMPROBAR EL CORRECTO FUNCIONAMIENTO DE LAS FUNCIONES

SELECT calcular_comision_cant_auditorias(55, 700000, '202301') FROM DUAL;

SELECT calcular_comision_monto_auditado(55,'202301') FROM DUAL;

SELECT calcular_comision_prof_crit(55, 700000, 5, '202301') FROM DUAL;

SELECT calcular_comision_extra(700000,3) FROM DUAL;