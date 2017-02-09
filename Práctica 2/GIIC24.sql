--Apartado 1-----------------------------------------------------------------------
create or replace 
PROCEDURE PEDIDOS_CLIENTE
(DNICLIENTE CHAR) IS
v_DNI Clientes.dni%TYPE;
v_Cliente Clientes%ROWTYPE;

CURSOR cursorPedidos IS
SELECT CLIENTE, CODIGO, FECHA_HORA_PEDIDO, FECHA_HORA_ENTREGA, ESTADO, IMPORTETOTAL
FROM Pedidos;
v_DNIEXISTE NUMBER;
DNINOEXISTE EXCEPTION;

v_PEDIDOEXISTE NUMBER;
PEDIDONOEXISTE EXCEPTION;
BEGIN

  SELECT SUBSTR(DNICLIENTE,0,9) INTO v_DNI FROM DUAL;
  
  SELECT COUNT(*) INTO v_DNIEXISTE FROM Clientes  WHERE dni  LIKE v_DNI; 
  
  IF v_DNIEXISTE = 0 THEN
    RAISE DNINOEXISTE;
  END IF;
  
  SELECT * INTO v_Cliente FROM Clientes WHERE dni  LIKE v_DNI;
  dbms_output.put_line('Datos personales del cliente');
  dbms_output.put_line(rpad('Nombre',15,' ')||rpad('Apellido',15,' ')||rpad('Calle',15,' ')||rpad('Número',15,' ')
  ||rpad('Piso',15,' ')||rpad('Localidad',15,' ')||rpad('Código Postal',20,' ')||rpad('Telefono',15,' ')
  ||rpad('Usuario',15,' ')||rpad('Contraseña',15,' '));
  dbms_output.put_line(rpad(v_Cliente.nombre,15,' ')||rpad(v_Cliente.apellido,15,' ')||rpad(v_Cliente.calle,15,' ')
  ||rpad(v_Cliente.numero,15,' ')  ||rpad(v_Cliente.piso,15,' ')||rpad(v_Cliente.localidad,15,' ')||rpad(v_Cliente.codigopostal,20,' ')
  ||rpad(v_Cliente.telefono,15,' ')||rpad(v_Cliente.usuario,15,' ')||rpad(v_Cliente.pass,15,' '));
  

  dbms_output.put_line(' ---------------------------------------------------------------------------------------------------------');
 
  dbms_output.put_line('Datos de los pedidos asociados al cliente');
  --------
  SELECT COUNT(*) INTO v_PEDIDOEXISTE FROM Pedidos  WHERE Cliente  LIKE v_DNI; 
  
  IF v_PEDIDOEXISTE = 0 THEN
    RAISE PEDIDONOEXISTE;
  END IF;
  --------
  dbms_output.put_line(rpad('Código',15,' ')||rpad('Fecha',15,' ')||rpad('Fecha de entrega',15,' ')||rpad('Estado',15,' ')
  ||rpad('Importe total',15,' '));
  FOR v_Pedido IN cursorPedidos LOOP
    IF v_Pedido.Cliente = v_DNI THEN
      dbms_output.put_line(rpad(v_Pedido.CODIGO,15,' ')||rpad(v_Pedido.fecha_hora_pedido,15,' ')
      ||rpad(v_Pedido.fecha_hora_entrega,15,' ')||rpad(v_Pedido.estado,15,' ')
  ||rpad(v_Pedido.importetotal,15,' '));
    END IF;
  END LOOP;
  
  EXCEPTION
  WHEN DNINOEXISTE THEN
    dbms_output.put_line('El cliente no existe');
  WHEN PEDIDONOEXISTE THEN
    dbms_output.put_line('El cliente no tiene pedidos asociados');
  
END;
--Apartado 2-----------------------------------------------------------------------
create or replace PROCEDURE REVISA_PRECIO_CON_COMISION IS
v_DNI Clientes.dni%TYPE;
v_Cliente Clientes%ROWTYPE;

CURSOR cursorPedidos IS
SELECT CLIENTE, CODIGO, FECHA_HORA_PEDIDO, FECHA_HORA_ENTREGA, ESTADO, IMPORTETOTAL
FROM Pedidos;
CURSOR cursorContiene IS
SELECT RESTAURANTE, PLATO, PEDIDO, UNIDADES, PRECIOCONCOMISION
FROM Contiene;

v_FilasActualizadas NUMBER;
v_CONTPEDIDOS NUMBER;
v_PrecioPlatoConComision CONTIENE.PRECIOCONCOMISION%TYPE;
v_PrecioPlato PLATOS.PRECIO%TYPE;
v_Comision RESTAURANTES.COMISION%TYPE;
v_ComisionPlato NUMBER;
BEGIN 
 
    v_FilasActualizadas := 0;
    FOR v_Contiene IN cursorContiene LOOP
      select precio INTO v_PrecioPlato FROM PLATOS WHERE
      nombre LIKE v_Contiene.plato;
        select comision INTO v_Comision FROM RESTAURANTES WHERE
        codigo = v_Contiene.restaurante;
        v_ComisionPlato := v_PrecioPlato * (v_Comision/100);
        v_PrecioPlatoConComision := v_ComisionPlato + v_PrecioPlato; 
        IF V_Contiene.PRECIOCONCOMISION IS  NOT NULL THEN
          IF V_Contiene.PRECIOCONCOMISION <> v_PrecioPlatoConComision THEN
           UPDATE  Contiene SET PRECIOCONCOMISION = v_PrecioPlatoConComision
           WHERE Restaurante = v_Contiene.restaurante 
           AND Plato = v_Contiene.plato 
           AND Pedido = v_Contiene.Pedido;
           v_FilasActualizadas := v_FilasActualizadas +1;
          END IF;
        ELSE
           UPDATE  Contiene SET PRECIOCONCOMISION = v_PrecioPlatoConComision 
           WHERE Restaurante = v_Contiene.restaurante 
           AND Plato = v_Contiene.plato 
           AND Pedido = v_Contiene.Pedido;
           v_FilasActualizadas := v_FilasActualizadas + 1;
        END IF;              
   END LOOP; 
  IF v_FilasActualizadas = 0 THEN
  dbms_output.put_line('Ningun cambio den los datos de contiene');
  ELSE
    dbms_output.put_line('Se han modificado '||v_FilasActualizadas||' filas de la tabla contiene.');
  END IF;
END;

--Apartado 3-----------------------------------------------------------------------
create or replace PROCEDURE REVISA_PEDIDOS IS
v_DNI Clientes.dni%TYPE;
v_Cliente Clientes%ROWTYPE;
 
CURSOR cursorPedidos IS
SELECT CLIENTE, CODIGO, FECHA_HORA_PEDIDO, FECHA_HORA_ENTREGA, ESTADO, IMPORTETOTAL
FROM Pedidos FOR UPDATE OF importeTotal;
CURSOR cursorContiene IS
SELECT RESTAURANTE, PLATO, PEDIDO, UNIDADES, PRECIOCONCOMISION
FROM Contiene;
 
e_precioComisionNull EXCEPTION;
v_CONTPEDIDOS NUMBER;
v_PrecioPlatoConComision Contiene.PRECIOCONCOMISION%TYPE;
v_FilasActualizadas NUMBER;
BEGIN
  v_FilasActualizadas := 0;
  FOR v_Pedido IN cursorPedidos LOOP
   v_PrecioPlatoConComision := 0;
    FOR v_Contiene IN cursorContiene LOOP
    IF v_Pedido.Codigo = v_Contiene.Pedido THEN
        IF V_Contiene.PRECIOCONCOMISION IS NULL THEN
        RAISE  e_precioComisionNull; 
        END IF;
        v_PrecioPlatoConComision := v_PrecioPlatoConComision + v_Contiene.PRECIOCONCOMISION*v_Contiene.unidades;
    END IF;               
   END LOOP; 
   IF v_Pedido.IMPORTETOTAL IS NOT NULL THEN
       IF  v_PrecioPlatoConComision <> v_Pedido.IMPORTETOTAL  THEN
       UPDATE Pedidos SET importeTotal = v_PrecioPlatoConComision WHERE CURRENT OF cursorPedidos;
         v_FilasActualizadas := v_FilasActualizadas + 1;
       END IF;
       
  ELSE
    UPDATE Pedidos SET importeTotal = v_PrecioPlatoConComision  WHERE CURRENT OF cursorPedidos;
      v_FilasActualizadas := v_FilasActualizadas + 1;
  END IF;
  END LOOP;
  
   IF v_FilasActualizadas = 0 THEN
  dbms_output.put_line('Ningun cambio den los datos de pedidos');
  ELSE
    dbms_output.put_line('Se han modificado '||v_FilasActualizadas||' filas de la tabla pedidos.');
  END IF;
  
  EXCEPTION
  WHEN e_precioComisionNull THEN
    dbms_output.put_line('Hay filas de la tabla Contiene que tienen el campo PRECIOCONCOMISION NULO');--Asumimos que ya deberia tener un valor
 
END;

--Apartado 4-----------------------------------------------------------------------------
create or replace PROCEDURE DATOS_CLIENTES IS

v_DNI CLientes.DNI%TYPE;
v_SUMIMPORTE NUMBER;
v_SUMIMPORTECLIENTES NUMBER;
v_NUMPEDIDOS NUMBER;
CURSOR cursorClientes IS SELECT* FROM clientes;
BEGIN
  v_SUMIMPORTECLIENTES := 0;
  DBMS_OUTPUT.PUT_LINE(rpad('DNI',15,' ')||lpad('SUMA DEL IMPORTE TOTAL DE SUS PEDIDOS',45,' '));
FOR v_clientes IN cursorClientes LOOP 
  SELECT COUNT(*) INTO v_NUMPEDIDOS FROM Pedidos  WHERE Cliente  LIKE v_clientes.DNI; 
  if v_NUMPEDIDOS = 0 THEN 
     DBMS_OUTPUT.PUT_LINE(rpad(v_clientes.DNI,15,' ')||lpad(0||' '||'€',45,' '));
  ELSE
    SELECT CLIENTES.DNI, SUM(IMPORTETOTAL) INTO v_DNI, v_SUMIMPORTE FROM PEDIDOS, CLIENTES WHERE CLIENTES.DNI = PEDIDOS.CLIENTE AND CLIENTES.DNI = v_clientes.DNI GROUP BY CLIENTES.DNI;
    DBMS_OUTPUT.PUT_LINE(rpad(v_DNI,15,' ')||lpad(v_SUMIMPORTE||' '||'€',45,' '));
    v_SUMIMPORTECLIENTES := v_SUMIMPORTECLIENTES + v_SUMIMPORTE;
  END IF;
END LOOP;
  DBMS_OUTPUT.PUT_LINE(rpad('Importe total de pedidos',30,'.') || lpad(v_SUMIMPORTECLIENTES||' '||'€',30,'.'));

END;
--Apartado 5-----------------------------------------------------------------------------
create or replace PROCEDURE LLAMADA IS
BEGIN
  REVISA_PRECIO_CON_COMISION();
  REVISA_PEDIDOS();
  DATOS_CLIENTES();
--rollback; 
END;