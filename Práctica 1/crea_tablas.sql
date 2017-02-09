DROP TABLE Restaurantes cascade constraints;
DROP TABLE Pedidos cascade constraints;
DROP TABLE Contiene cascade constraints;
DROP TABLE Descuentos cascade constraints;
DROP TABLE Clientes cascade constraints;
DROP TABLE AreasCobertura cascade constraints;
DROP TABLE Horarios cascade constraints;
DROP TABLE Platos cascade constraints;

DROP INDEX I_CatPlatos;
DROP SEQUENCE Seq_CodPedidos;

CREATE TABLE Clientes (
  dni CHAR(9) NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  apellido VARCHAR(255) NOT NULL,
  calle CHAR(20),
  numero NUMBER(4) NOT NULL,
  piso CHAR(5),
  localidad CHAR(15),
  CodigoPostal CHAR(5),
  telefono CHAR(9),
  usuario CHAR(8) NOT NULL,
  pass CHAR(8) DEFAULT 'Nopass',
  UNIQUE(usuario),
  PRIMARY KEY(dni)
);

CREATE TABLE Restaurantes(
 codigo NUMBER(8) NOT NULL , 
 nombre CHAR(20) NOT NULL  ,
 calle CHAR(30) NOT NULL ,
 CodigoPostal CHAR(5) NOT NULL ,
 comision NUMBER(8,2) ,
 PRIMARY KEY(codigo)
);

CREATE TABLE Horarios(
 restaurante NUMBER(8) NOT NULL,
 DiaSemana CHAR(1) NOT NULL,
 hora_apertura DATE NOT NULL,
 hora_cierre DATE NOT NULL,
 PRIMARY KEY(restaurante,DiaSemana),
 FOREIGN KEY(restaurante) REFERENCES Restaurantes(codigo) ON DELETE CASCADE
);

CREATE TABLE AreasCobertura(
 restaurante NUMBER(8) NOT NULL , 
 CodigoPostal CHAR(5) NOT NULL  , 
 PRIMARY KEY(restaurante, CodigoPostal),
 FOREIGN KEY(restaurante) REFERENCES Restaurantes(codigo)
 
);

CREATE TABLE Platos(
  restaurante  NUMBER(8) NOT NULL,
  nombre CHAR(20) NOT NULL,
  precio NUMBER(8,2),
  descripcion CHAR(30),
  categoria CHAR(20) ,
  PRIMARY KEY(restaurante, nombre),
  FOREIGN KEY(restaurante) REFERENCES Restaurantes(codigo) ON DELETE CASCADE
);

CREATE INDEX I_CatPlatos ON Platos(categoria);
CREATE SEQUENCE Seq_CodPedidos INCREMENT BY 1 START WITH 1 NOMAXVALUE;

CREATE TABLE Descuentos(
 codigo NUMBER(8) NOT NULL , 
 fecha_caducidad DATE ,
 PorcentajeDescuento NUMBER(3) CHECK (PorcentajeDescuento >0 AND PorcentajeDescuento<=100) ,
 PRIMARY KEY(codigo)); 

CREATE TABLE Pedidos(
 codigo NUMBER(8) NOT NULL , 
 estado CHAR(9) DEFAULT 'REST' NOT NULL , 
 fecha_hora_pedido DATE NOT NULL ,
 fecha_hora_entrega DATE ,
 ImporteTotal NUMBER(8,2),  
 cliente CHAR(9) NOT NULL REFERENCES Clientes(dni),
 codigoDescuento Number(8) REFERENCES Descuentos(codigo) ON DELETE SET NULL ,
 PRIMARY KEY(codigo) , 
 CHECK (estado IN ('REST', 'CANCEL', 'RUTA', 'ENTREGADO','RECHAZADO'))
);

CREATE TABLE Contiene(
 restaurante NUMBER(8) NOT NULL , 
 plato CHAR(20) NOT NULL , 
 pedido NUMBER(8) NOT NULL REFERENCES Pedidos(codigo) ON DELETE CASCADE ,
 PrecioConComision NUMBER(8,2) ,
 unidades NUMBER(4)NOT NULL ,
 PRIMARY KEY(restaurante, plato, pedido) ,
 FOREIGN KEY(restaurante, plato) REFERENCES Platos(restaurante, nombre)
);