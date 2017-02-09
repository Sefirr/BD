--1. Listado con todos los datos de los clientes, ordenados por apellidos.
SELECT * FROM Clientes ORDER BY apellido;
--2.Horarios de cada uno de los restaurantes. Para cada restaurante aparecer� su nombre y el d�a de la
--semana (sustituyendo la letra por el nombre completo del d�a) y la hora de apertura y de cierre, en
--formato HH:MM
SELECT DISTINCT Restaurantes.NOMBRE, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Horarios.DIASEMANA,'L','Lunes'),'M','Martes'),'X','Miercoles'),'J','Jueves'),'V','Viernes'),'S','Sabado'),'D','Domingo') "DIA DE LA SEMANA", to_char(Horarios.HORA_APERTURA,'HH:MM') "HORA DE APERTURA", to_char(Horarios.HORA_CIERRE,'HH:MM')
"HORA DE CIERRE"
FROM Restaurantes, Horarios
WHERE Restaurantes.CODIGO = Horarios.RESTAURANTE;

--3. �Qu� clientes (DNI, nombre y apellidos) han pedido alguna vez platos de la categor�a �picante�?
SELECT DISTINCT CLIENTES.DNI, Clientes.NOMBRE, CLIENTES.APELLIDO
FROM Clientes, Pedidos, Contiene, Platos
WHERE Clientes.dni = Pedidos.CLIENTE
AND Pedidos.Codigo = Contiene.PEDIDO
AND Contiene.PLATO = Platos.NOMBRE
AND Platos.CATEGORIA LIKE 'picante%';

--4. �Qu� clientes (DNI, nombre y apellidos) han pedido platos en todos los restaurantes?
-- Nombre de los clientes tales que no haya ning�n restaurante en los que no hayan hecho pedidos.
SELECT DISTINCT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO
FROM Clientes
WHERE NOT EXISTS (
SELECT Restaurantes.CODIGO FROM Restaurantes WHERE NOT EXISTS
(SELECT Pedidos.CODIGO from Pedidos , Contiene WHERE Pedidos.CODIGO = Contiene.PEDIDO AND  Restaurantes.CODIGO= Contiene.RESTAURANTE AND Clientes.DNI = Pedidos.CLIENTE));

--5. �Qu� clientes (DNI, nombre y apellidos) no han recibido a�n sus pedidos?
--CLientes tales que haya alg�n pedido que no haya sido recibido
SELECT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO
FROM Clientes
WHERE EXISTS
(SELECT Pedidos.Codigo FROM Pedidos WHERE Clientes.DNI = Pedidos.CLIENTE AND Pedidos.ESTADO IN ('REST','RUTA') );

--6. Muestra todos los datos (salvo los platos que lo componen) del pedido (o pedidos) de mayor importe
--total. Considera que puede haber varios pedidos con el mismo importe.
SELECT *
FROM PEDIDOS
WHERE IMPORTETOTAL = (SELECT MAX(IMPORTETOTAL) FROM PEDIDOS);

--7.Obt�n el valor medio de los pedidos de cada cliente, mostrando su DNI, nombre y apellidos.
SELECT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO, TRUNC(AVG(Pedidos.IMPORTETOTAL),2)
FROM Clientes, Pedidos
WHERE Clientes.DNI = Pedidos.Cliente
GROUP BY Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO;

--8. Muestra para cada restaurante (c�digo y nombre) el n�mero total de platos vendidos y el precio
--acumulado que obtuvieron.
SELECT Restaurantes.CODIGO, Restaurantes.NOMBRE, SUM(Contiene.UNIDADES) "PLATOS VENDIDOS", SUM(Platos.PRECIO*Contiene.UNIDADES) "PRECIO ACUMULADO"
FROM Restaurantes, Contiene, Platos
WHERE Restaurantes.CODIGO = Contiene.RESTAURANTE
AND Contiene.PLATO = Platos.NOMBRE
GROUP BY Restaurantes.CODIGO, Restaurantes.NOMBRE;

--9. Nombre y apellidos de aquellos clientes que pidieron platos de m�s de 15 �.
--Clientes tales que existan pedidos en los que haya platos de m�s de 15�
SELECT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO
FROM Clientes
WHERE EXISTS (SELECT Pedidos.CODIGO FROM Pedidos WHERE Pedidos.CLIENTE = Clientes.DNI AND EXISTS 
(SELECT Platos.NOMBRE FROM Contiene, Platos WHERE Platos.NOMBRE = Contiene.PLATO AND Pedidos.CODIGO = Contiene.PEDIDO AND Platos.PRECIO > 15));

-- 10. Para cada cliente (mostrar DNI, nombre y apellidos) mostrar el n�mero de restaurantes que cubren el
--�rea en el que vive el cliente. Si alg�n cliente no est� cubierto por ninguno, debe aparecer 0
SELECT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO, count(*) "N�MERO DE RESTAURANTES"
FROM Clientes, AreasCobertura
WHERE Clientes.CODIGOPOSTAL = AreasCobertura.CODIGOPOSTAL
GROUP BY Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO
UNION ALL
SELECT Clientes.DNI, Clientes.NOMBRE, Clientes.APELLIDO, 0
FROM Clientes
WHERE Clientes.CODIGOPOSTAL NOT IN(SELECT AC.CODIGOPOSTAL FROM AreasCobertura AC);