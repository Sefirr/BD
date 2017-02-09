
/*Javier Villarreal & Rafael Gómez Bermejo*/
/*				Practica 2				  */
/*               GRUPO B				  */


drop table Cheque cascade constraints;
drop table Cliente cascade constraints;
drop table Carrito cascade constraints;
drop table Pedido cascade constraints;
drop table Producto cascade constraints;
drop table TienePed_Pro cascade constraints;
drop table Repartidor cascade constraints;
drop table TieneRep_Zona cascade constraints;
drop table Zonas cascade constraints;
drop SEQUENCE IdPedido;
drop SEQUENCE IdCheque;
drop PROCEDURE "CONFIRMARPEDIDO";
drop PROCEDURE "PEDIDOSPENDIENTESREPARTO";
drop TRIGGER "REGISTRARCHEQUE"; 

/***********************************************************/
 create table Zonas
( CP CHAR(5) PRIMARY KEY);
/**********************************************************/
create table Repartidor
( NumEmpleado CHAR(10) PRIMARY KEY); 
  /***********************************************************/ 
create table Cliente
( Email VARCHAR(40) PRIMARY KEY,
  Nombre VARCHAR(25) NOT NULL,
  Apellidos VARCHAR(25) NOT NULL,
  Direccion VARCHAR(60) NOT NULL,
  NumTarjeta CHAR(30) NOT NULL,
  CP CHAR(5) NOT NULL,
  NumSocio CHAR(30),
  Telefono CHAR(15),
  CONSTRAINT cli_zon_FK FOREIGN KEY(CP) REFERENCES Zonas);
/***********************************************************/ 
  create table Pedido
( NumPedido CHAR(10) PRIMARY KEY,
  Importe NUMBER(6,2) DEFAULT 0,
  FechaPedido DATE NOT NULL,
  Email VARCHAR(40) NOT NULL,
  NumEmpleado CHAR(10),
  CONSTRAINT oed_cli_FK FOREIGN KEY(Email) REFERENCES Cliente,
  CONSTRAINT ped_rep_FK FOREIGN KEY(NumEmpleado) REFERENCES Repartidor);
/***********************************************************/ 
  create table Producto
( Codigo CHAR(10) PRIMARY KEY,
  Tipo VARCHAR(15) NOT NULL,
  Descuento CHAR(5) NOT NULL,
  Precio NUMBER(6,2) DEFAULT 0,
  Descripcion VARCHAR(100) NOT NULL);
/***********************************************************/
  create table TienePed_Pro
( Cantidad NUMBER(3) CHECK (Cantidad > 0),
  Codigo CHAR(10) NOT NULL,
  NumPedido CHAR(10) NOT NULL,
  CONSTRAINT pp_PK PRIMARY KEY(Codigo, NumPedido),
  CONSTRAINT prod_FK FOREIGN KEY(Codigo) REFERENCES Producto on delete cascade,
  CONSTRAINT ped_FK FOREIGN KEY(NumPedido) REFERENCES Pedido on delete cascade);
/*********************************************************/
  create table TieneRep_Zona
( CP CHAR(5) NOT NULL,
  NumEmpleado CHAR(10) NOT NULL,
  CONSTRAINT rz_PK PRIMARY KEY(CP, NumEmpleado),
  CONSTRAINT zona_FK FOREIGN KEY(CP) REFERENCES Zonas on delete cascade,
  CONSTRAINT rep_FK FOREIGN KEY(NumEmpleado) REFERENCES Repartidor on delete cascade);
/***********************************************************/
  create table Cheque
( NumCheque CHAR(10) NOT NULL,
  Fecha DATE NOT NULL,
  ImporteMin NUMBER(6,2) NOT NULL,
  ImporteDesc NUMBER(6,2) NOT NULL,
  NumPedido CHAR(10) DEFAULT NULL,
  Email VARCHAR(40),
  CONSTRAINT cheque_PK PRIMARY KEY(NumCheque, Email),
  CONSTRAINT cheque_ped_FK FOREIGN KEY(NumPedido) REFERENCES Pedido,
  CONSTRAINT cheque_cli_FK FOREIGN KEY(Email) REFERENCES Cliente);
  
  /***********************************************************/
create table Carrito
( Cantidad NUMBER(3) CHECK (CANTIDAD > 0),
  Email VARCHAR(40) NOT NULL,
  Codigo CHAR(10) NOT NULL,
  CONSTRAINT carr_cli_PK PRIMARY KEY(Email, Codigo),
  CONSTRAINT carr_em_FK FOREIGN KEY(Email) REFERENCES Cliente,
  CONSTRAINT carr_cod_FK FOREIGN KEY(Codigo) REFERENCES Producto);
  
  
  
  INSERT INTO Zonas (CP) VALUES('28025');
  INSERT INTO Zonas (CP) VALUES ('28022');
  INSERT INTO Cliente  (Email, Nombre, Apellidos, Direccion, NumTarjeta, CP, NumSocio) VALUES ('ejemplo@email.org', 'Perico', 'De los Palotes','Calle falsa,123','23424566','28022', '012345678901234567890123456789');
  INSERT INTO Cliente  (Email, Nombre, Apellidos, Direccion, NumTarjeta, CP) VALUES ('ejemplo2@email.org', 'Manolo', 'El del Bombo','Calle capicua,435','43773328','28025');
  INSERT INTO Producto (Codigo, Tipo, Descuento, Precio, Descripcion) VALUES ('0123456789','ENVASADO','2x1',2.12,'El yogur es un producto envasado.');
  INSERT INTO Carrito (Cantidad, Email, Codigo) VALUES (18,'ejemplo@email.org','0123456789');
  INSERT INTO Repartidor  (NumEmpleado) VALUES ('0123456789');
  INSERT INTO TieneRep_Zona  (NumEmpleado,CP) VALUES ('0123456789','28022');
  INSERT INTO TieneRep_Zona  (NumEmpleado,CP) VALUES ('0123456789','28025');
  INSERT INTO Repartidor  (NumEmpleado) VALUES ('0123456799');
  INSERT INTO TieneRep_Zona  (NumEmpleado,CP) VALUES ('0123456799','28022');
  
  
  
  create sequence IdPedido  MINVALUE 1 START WITH 1
    INCREMENT BY 1 NOCACHE;
	
  create sequence IdCheque  MINVALUE 1 START WITH 1
    INCREMENT BY 1 NOCACHE;
  
create or replace PROCEDURE "CONFIRMARPEDIDO"
  (v_EmailCli VARCHAR)
  IS
    CARRITO_VACIO EXCEPTION;
    v_IdPedido PEDIDO.NUMPEDIDO%TYPE;
    v_Email CARRITO.EMAIL%TYPE;
    v_Descuento Cheque.ImporteDesc%TYPE;
    v_Importe PEDIDO.IMPORTE%TYPE;
    v_PrecioProducto PRODUCTO.PRECIO%TYPE;
    v_DescripcionProducto PRODUCTO.DESCRIPCION%TYPE;
    v_Fecha PEDIDO.FECHAPEDIDO%TYPE;
    v_DescuentoProcede NUMBER;
    v_CarritoV NUMBER;
    TB constant varchar2(1):=CHR(9);
    
    CURSOR cursorCarrito IS
    SELECT Cantidad, Email, Codigo FROM Carrito;
    CURSOR cursorPed_Pro IS
    SELECT Cantidad, Codigo, NumPedido FROM TienePed_Pro;
    CURSOR cursorCheque IS
    SELECT NumCheque,ImporteMin, ImporteDesc, NumPedido, Email FROM Cheque; 
  BEGIN
    SELECT SUBSTR(v_EmailCli,0,40) INTO v_Email FROM DUAL;
    v_Importe := 0;
    v_Descuento := 0;
    v_DescuentoProcede := 0;
    v_CarritoV := 0;
    SELECT SYSDATE INTO v_Fecha  FROM DUAL;
    INSERT INTO Pedido (NumPedido, FechaPedido, Email) VALUES (IdPedido.NEXTVAL,v_Fecha,v_Email);
    
    v_IdPedido := IdPedido.CURRVAL;
    FOR v_Carrito IN cursorCarrito LOOP  
      IF V_Carrito.Email = v_Email THEN
        SELECT Precio INTO v_PrecioProducto FROM Producto WHERE Codigo = v_Carrito.Codigo;
        v_Importe := v_Importe + v_PrecioProducto*v_Carrito.Cantidad;
        v_CarritoV := 1;
        INSERT INTO TienePed_Pro (Cantidad, Codigo, NumPedido) VALUES (v_Carrito.Cantidad, v_Carrito.Codigo,v_IdPedido);
        DELETE FROM Carrito WHERE Email like '%'||v_Email||'%' and Codigo like '%'||v_Carrito.Codigo||'%' ;
      END IF;
    END LOOP;

    IF v_CarritoV = 0 THEN
      RAISE CARRITO_VACIO;
    END IF;
    
    FOR v_Cheque IN cursorCheque LOOP  
      IF v_Cheque.NumPedido IS NULL and v_Cheque.ImporteMin <= v_Importe and v_Cheque.Email = v_Email THEN
        v_Descuento := v_Cheque.ImporteDesc;
        UPDATE Cheque SET NumPedido = v_IdPedido WHERE NumCheque like '%'||v_Cheque.NumCheque||'%' and Email like '%'||v_Email||'%';
        v_DescuentoProcede := 1;
      END IF;
      EXIT WHEN v_Cheque.NumPedido IS NULL and v_Cheque.ImporteMin <= v_Importe and v_Cheque.Email = v_Email;
    END LOOP;
    
    UPDATE Pedido SET Importe = v_Importe - V_Descuento WHERE NumPedido like '%'||v_IdPedido||'%';
    
    

    DBMS_OUTPUT.PUT_LINE(rpad('Código',15,' ')||TB||rpad('Descripción',50,' ')||TB||rpad('Unidades',15,' ')||rpad('Precio del producto',25,' '));
    DBMS_OUTPUT.PUT_LINE(rpad('-',105,'-')); 
    FOR v_Producto in cursorPed_Pro LOOP
      IF v_Producto.NumPedido = IdPedido.CURRVAL THEN
        SELECT Descripcion, Precio INTO v_DescripcionProducto, v_PrecioProducto FROM Producto WHERE Codigo = v_Producto.Codigo;
        DBMS_OUTPUT.PUT_LINE(rpad(v_Producto.Codigo,15,' ')||TB||rpad(v_DescripcionProducto,50,' ')||TB||rpad(v_Producto.Cantidad,15,' ')||TB||rpad(v_PrecioProducto,25,' '));
      END IF;
    END LOOP;
    v_Importe := v_Importe + v_Descuento;
    DBMS_OUTPUT.PUT_LINE('Importe:'||TB||v_Importe);
    if v_DescuentoProcede = 1 THEN
      DBMS_OUTPUT.PUT_LINE('Descuento: SI PROCEDE'||TB||'Importe del descuento:'||TB||v_Descuento);
    ELSE
      DBMS_OUTPUT.PUT_LINE('Descuento: NO PROCEDE'||TB||'Importe del descuento: NO APLICA');
    END IF;
    v_Importe := v_Importe - v_Descuento;
    DBMS_OUTPUT.PUT_LINE('Importe total: '||TB||TB||v_Importe);
   
    EXCEPTION
    WHEN CARRITO_VACIO THEN
      DBMS_OUTPUT.PUT_LINE('Estás intentando confirmar un pedido con el carrito vacio.');
  END;

  
 
create or replace PROCEDURE "PEDIDOSPENDIENTESREPARTO"
  IS
    v_RepDisponible NUMBER;
    v_CP CLIENTE.CP%TYPE;
    v_CPEmpleado TIENEREP_ZONA.CP%TYPE;
    TB constant varchar2(1):=CHR(9);
    CURSOR cursorPedidos IS
    SELECT NumPedido, Email, NumEmpleado FROM Pedido;
    CURSOR cursorRepartidores IS
    SELECT NumEmpleado FROM Repartidor;
  BEGIN
  DBMS_OUTPUT.PUT_LINE(rpad('Número de pedido',30,' ')||TB||rpad('Repartidores disponibles',25,' '));
  DBMS_OUTPUT.PUT_LINE(rpad('-',55,'-')); 
  FOR v_Pedido IN cursorPedidos LOOP
    v_RepDisponible := 0;
    IF v_Pedido.NumEmpleado IS NULL THEN
      DBMS_OUTPUT.PUT(rpad(v_Pedido.NumPedido,30,' '));
      SELECT CP INTO v_CP FROM Cliente WHERE Email = v_Pedido.Email;
      FOR v_Empleado IN cursorRepartidores LOOP
        SELECT CP INTO v_CPEmpleado FROM TieneRep_Zona WHERE NumEmpleado = v_Empleado.NumEmpleado and CP = v_CP;
        IF v_CPEmpleado = v_CP THEN
          DBMS_OUTPUT.PUT(v_Empleado.NumEmpleado||' / ');
          v_RepDisponible := 1;
        END IF;
      END LOOP;
      IF v_RepDisponible != 1 THEN
        DBMS_OUTPUT.PUT(rpad('No hay repartidores disponibles.',25,' '));
      END IF;
      DBMS_OUTPUT.PUT_LINE('');
    END IF;
  END LOOP;
    
  END;
  
  
  create or replace TRIGGER "REGISTRARCHEQUE" 
AFTER UPDATE OF IMPORTE ON PEDIDO
FOR EACH ROW
DECLARE
  v_NumSocio Cliente.NumSocio%TYPE;
BEGIN
  SELECT NumSocio INTO v_NumSocio FROM Cliente WHERE Email = :OLD.EMAIL;
  IF v_NumSocio IS NOT NULL THEN
    INSERT INTO Cheque (NumCheque, Fecha, ImporteMin , ImporteDesc, Email) VALUES (IdCheque.NEXTVAL,add_months(SYSDATE,3),0.5*:NEW.IMPORTE,0.03*:NEW.IMPORTE,:OLD.EMAIL);
  END IF;
END;


ALTER TRIGGER REGISTRARCHEQUE ENABLE;