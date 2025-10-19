create or replace TRIGGER TRG_AUMENTO_COMISION_BANCO_SANTANDER
BEFORE INSERT ON DETALLE_COMISIONES_AUDITORIAS_MES
FOR EACH ROW
DECLARE
  v_limite CONSTANT NUMBER := 500000;
BEGIN
  -- Solo aplica si la empresa es Banco Santander (COD_EMPRESA = 3)
  IF :NEW.cod_empresa = 3 THEN
    :NEW.total_comision_audit := :NEW.total_comision_audit * 1.10;

    -- Validación de límite máximo
    IF :NEW.total_comision_audit > v_limite THEN
      :NEW.total_comision_audit := v_limite;
    END IF;
  END IF;
END TRG_AUMENTO_COMISION_BANCO_SANTANDER;