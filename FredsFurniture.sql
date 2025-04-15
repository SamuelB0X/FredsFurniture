SET
	SEARCH_PATH TO CC_USER,
	PUBLIC;

--1. Mostrar los primeros 10 registros de la tabla STORE
SELECT
	*
FROM
	STORE
LIMIT
	10;

/* 
Para normalizar la base de datos,
Creo que las columnas que deberían ser transladarse a tablas separadas serían:

-Separaría las órdenes de compra con su id y la fecha. (order_id y order_date)
-De los clientes Separaría con su id, número de telefono y email (customer_id, coustomer_phone y customer_email)
-Separaría los items que tienen varias columnas que hacen referencia a ids, nombres y precios de los productos
(item_1_id, item_1_name, item_1_price, item_2_id, item_2_name, item_2_price, item_3_id, item_3_name, item_3_price)
*/

--2. Contar la cantidad de pedidos únicos
SELECT
	COUNT(DISTINCT (ORDER_ID))
FROM
	STORE;

--2.1 Número total de clientes diferentes (algunos con múltiples pedidos)
SELECT
	COUNT(DISTINCT (CUSTOMER_ID))
FROM
	STORE;

--3. Obtener la información de contacto del cliente con ID 1
SELECT
	CUSTOMER_ID,
	CUSTOMER_EMAIL,
	CUSTOMER_PHONE
FROM
	STORE
WHERE
	CUSTOMER_ID = 1;

--4. Obtener información del artículo con ID 4
SELECT
	ITEM_1_ID,
	ITEM_1_NAME,
	ITEM_1_PRICE
FROM
	STORE
WHERE
	ITEM_1_ID = 4;

--4.1 Contar los pedidos realizados por el cliente con ID 1
SELECT
	COUNT(*)
FROM
	STORE
WHERE
	CUSTOMER_ID = 1;

--5. Crear la tabla CUSTOMERS con datos únicos de clientes
CREATE TABLE CUSTOMERS AS
SELECT DISTINCT
	CUSTOMER_ID,
	CUSTOMER_EMAIL,
	CUSTOMER_PHONE
FROM
	STORE;

--6. Establecer CUSTOMER_ID como clave primaria de la tabla CUSTOMERS
ALTER TABLE CUSTOMERS
ADD PRIMARY KEY (CUSTOMER_ID);

--7. Crear la tabla ITEMS combinando todos los productos únicos
CREATE TABLE ITEMS AS
SELECT
	ITEM_1_ID AS ITEM_ID,
	ITEM_1_NAME AS ITEM_NAME,
	ITEM_1_PRICE AS ITEM_PRICE
FROM
	STORE
WHERE
	ITEM_1_ID IS NOT NULL
UNION
SELECT
	ITEM_2_ID AS ITEM_ID,
	ITEM_2_NAME AS ITEM_NAME,
	ITEM_2_PRICE AS ITEM_PRICE
FROM
	STORE
WHERE
	ITEM_2_ID IS NOT NULL
UNION
SELECT
	ITEM_3_ID AS ITEM_ID,
	ITEM_3_NAME AS ITEM_NAME,
	ITEM_3_PRICE AS ITEM_PRICE
FROM
	STORE
WHERE
	ITEM_3_ID IS NOT NULL;

--8. Definir ITEM_ID como la clave primaria de la tabla ITEMS
ALTER TABLE ITEMS
ADD PRIMARY KEY (ITEM_ID);

--9. Crear la tabla ORDERS_ITEMS relacionando pedidos con productos
CREATE TABLE ORDERS_ITEMS AS
SELECT
	ORDER_ID,
	ITEM_1_ID AS ITEM_ID
FROM
	STORE
WHERE
	ITEM_1_ID IS NOT NULL
UNION ALL
SELECT
	ORDER_ID,
	ITEM_2_ID AS ITEM_ID
FROM
	STORE
WHERE
	ITEM_2_ID IS NOT NULL
UNION ALL
SELECT
	ORDER_ID,
	ITEM_3_ID AS ITEM_ID
FROM
	STORE
WHERE
	ITEM_3_ID IS NOT NULL;

--10. Crear la tabla ORDERS con los datos esenciales del pedido
CREATE TABLE ORDERS AS
SELECT DISTINCT
	ORDER_ID,
	ORDER_DATE,
	CUSTOMER_ID
FROM
	STORE;

--11. Establecer ORDER_ID como clave primaria en ORDERS
ALTER TABLE ORDERS
ADD PRIMARY KEY (ORDER_ID);

--12. Establecer relación entre ORDERS y CUSTOMERS
ALTER TABLE ORDERS
ADD FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID);

--12.1 Establecer relación entre ORDERS_ITEMS e ITEMS
ALTER TABLE ORDERS_ITEMS
ADD FOREIGN KEY (ITEM_ID) REFERENCES ITEMS (ITEM_ID);

--13. Agregar otra clave foránea para vincular ORDERS_ITEMS con ORDERS
ALTER TABLE ORDERS_ITEMS
ADD FOREIGN KEY (ORDER_ID) REFERENCES ORDERS (ORDER_ID);

--14. Obtener correos de clientes con pedidos después del 25 de julio de 2019 (sin normalizar)
SELECT DISTINCT
	CUSTOMER_EMAIL
FROM
	STORE
WHERE
	ORDER_DATE > '2019-07-25';

--15. Igual a la anterior pero usando las tablas normalizadas
SELECT DISTINCT
	C.CUSTOMER_EMAIL
FROM
	CUSTOMERS C
	JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE
	O.ORDER_DATE > '2019-07-25';

--16. Contar cuántos pedidos contienen cada artículo (sin normalizar)
WITH
	ALL_ITEMS AS (
		SELECT
			ITEM_1_ID AS ITEM_ID
		FROM
			STORE
		UNION ALL
		SELECT
			ITEM_2_ID AS ITEM_ID
		FROM
			STORE
		WHERE
			ITEM_2_ID IS NOT NULL
		UNION ALL
		SELECT
			ITEM_3_ID AS ITEM_ID
		FROM
			STORE
		WHERE
			ITEM_3_ID IS NOT NULL
	)
SELECT
	ITEM_ID,
	COUNT(*) AS ORDER_COUNT
FROM
	ALL_ITEMS
GROUP BY
	ITEM_ID
ORDER BY
	ITEM_ID;

--17. Misma consulta anterior pero sobre tablas normalizadas
SELECT
	ITEM_ID,
	COUNT(*) AS ORDER_COUNT
FROM
	ORDERS_ITEMS
GROUP BY
	ITEM_ID
ORDER BY
	ITEM_ID;

--Consulta extra: clientes con más de un pedido y su email
SELECT
	C.CUSTOMER_EMAIL,
	COUNT(O.ORDER_ID) AS ORDER_COUNT
FROM
	CUSTOMERS C
	JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY
	C.CUSTOMER_ID,
	C.CUSTOMER_EMAIL
HAVING
	COUNT(O.ORDER_ID) > 1;

--Pedidos después del 15 de julio de 2019 que incluyan productos tipo "lamp"
SELECT
	COUNT(DISTINCT O.ORDER_ID) AS LAMP_ORDERS
FROM
	ORDERS O
	JOIN ORDERS_ITEMS OI ON O.ORDER_ID = OI.ORDER_ID
	JOIN ITEMS I ON OI.ITEM_ID = I.ITEM_ID
WHERE
	O.ORDER_DATE > '2019-07-15'
	AND I.ITEM_NAME LIKE '%lamp%';

--Pedidos que contengan productos con nombre que incluya "chair", sin restricción de fecha
SELECT
	COUNT(DISTINCT O.ORDER_ID) AS CHAIR_ORDERS
FROM
	ORDERS O
	JOIN ORDERS_ITEMS OI ON O.ORDER_ID = OI.ORDER_ID
	JOIN ITEMS I ON OI.ITEM_ID = I.ITEM_ID;