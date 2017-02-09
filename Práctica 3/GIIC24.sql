create or replace TRIGGER "insert_pedido"
AFTER INSERT ON CONTIENE 
FOR EACH ROW 
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
v_REGISTROVENTASEXISTE NUMBER;
v_FECHA PEDIDOS.FECHA_HORA_PEDIDO%TYPE;
BEGIN 
    SELECT COUNT(*) INTO v_REGISTROVENTASEXISTE FROM REGISTRO_VENTAS  WHERE COD_REST = :NEW.RESTAURANTE;
    IF v_REGISTROVENTASEXISTE = 0 THEN
      INSERT INTO REGISTRO_VENTAS (SELECT RESTAURANTE , SUM(PRECIOCONCOMISION*UNIDADES),MAX(FECHA_HORA_PEDIDO) FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :NEW.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE);
      UPDATE REGISTRO_VENTAS SET TOTAL_PEDIDOS= TOTAL_PEDIDOS+:NEW.PRECIOCONCOMISION*:NEW.UNIDADES WHERE COD_REST = :NEW.RESTAURANTE;
    ELSIF v_REGISTROVENTASEXISTE > 0 THEN
      SELECT MAX(FECHA_HORA_PEDIDO) INTO v_FECHA FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :NEW.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE;
      UPDATE REGISTRO_VENTAS SET TOTAL_PEDIDOS= TOTAL_PEDIDOS+:NEW.PRECIOCONCOMISION*:NEW.UNIDADES, FECHA_ULT_PEDIDO = v_FECHA WHERE COD_REST = :NEW.RESTAURANTE;
    END IF;
    COMMIT;
END;

create or replace TRIGGER "modify_pedido"
AFTER UPDATE OR DELETE ON CONTIENE 
FOR EACH ROW 
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
v_REGISTROVENTASEXISTE NUMBER;
v_FECHA PEDIDOS.FECHA_HORA_PEDIDO%TYPE;
BEGIN
    IF DELETING THEN
      SELECT COUNT(*) INTO v_REGISTROVENTASEXISTE FROM REGISTRO_VENTAS  WHERE COD_REST = :OLD.RESTAURANTE;
      IF v_REGISTROVENTASEXISTE = 0 THEN
        INSERT INTO REGISTRO_VENTAS (SELECT RESTAURANTE , SUM(PRECIOCONCOMISION*UNIDADES),MAX(FECHA_HORA_PEDIDO) FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :OLD.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE);
      END IF;
      SELECT MAX(FECHA_HORA_PEDIDO) INTO v_FECHA FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :OLD.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE;
      UPDATE REGISTRO_VENTAS SET TOTAL_PEDIDOS= TOTAL_PEDIDOS-:OLD.PRECIOCONCOMISION*:OLD.UNIDADES, FECHA_ULT_PEDIDO = v_FECHA WHERE COD_REST = :OLD.RESTAURANTE;
    ELSIF UPDATING THEN
      SELECT COUNT(*) INTO v_REGISTROVENTASEXISTE FROM REGISTRO_VENTAS  WHERE COD_REST = :NEW.RESTAURANTE;
      IF v_REGISTROVENTASEXISTE = 0 THEN
        INSERT INTO REGISTRO_VENTAS (SELECT RESTAURANTE , SUM(PRECIOCONCOMISION*UNIDADES),MAX(FECHA_HORA_PEDIDO) FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :NEW.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE);       
      END IF; 
       SELECT MAX(FECHA_HORA_PEDIDO) INTO v_FECHA FROM CONTIENE,PEDIDOS WHERE CONTIENE.RESTAURANTE = :NEW.RESTAURANTE AND CONTIENE.PEDIDO = PEDIDOS.CODIGO GROUP BY RESTAURANTE;
       UPDATE REGISTRO_VENTAS SET TOTAL_PEDIDOS= TOTAL_PEDIDOS - :OLD.PRECIOCONCOMISION*:OLD.UNIDADES + :NEW.PRECIOCONCOMISION*:NEW.UNIDADES, FECHA_ULT_PEDIDO = v_FECHA WHERE COD_REST = :NEW.RESTAURANTE;
    END IF;
    COMMIT;
END;

create or replace TRIGGER "control_detalle_pedidos"
AFTER INSERT OR UPDATE OR DELETE ON CONTIENE
FOR EACH ROW 
BEGIN 
IF INSERTING THEN
--instrucciones que se ejecutan si el trigger saltó por insertar filas
--REVISA_PEDIDOS();
UPDATE Pedidos SET IMPORTETOTAL = IMPORTETOTAL + :NEW.PRECIOCONCOMISION*:NEW.UNIDADES  WHERE Pedidos.CODIGO = :NEW.PEDIDO;
ELSIF UPDATING THEN
--instrucciones que se ejecutan si el trigger saltó por modificar filas
--REVISA_PEDIDOS();
UPDATE Pedidos SET IMPORTETOTAL = IMPORTETOTAL - :OLD.PRECIOCONCOMISION*:OLD.UNIDADES + :NEW.PRECIOCONCOMISION*:NEW.UNIDADES WHERE Pedidos.CODIGO = :NEW.PEDIDO;
ELSE
--REVISA_PEDIDOS();
UPDATE Pedidos SET IMPORTETOTAL = IMPORTETOTAL - :OLD.PRECIOCONCOMISION*:OLD.UNIDADES WHERE Pedidos.CODIGO = :OLD.PEDIDO;
END IF;
END;