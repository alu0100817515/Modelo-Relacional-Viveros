-- Creación de la Base de Datos
DROP DATABASE IF EXISTS Viveros;
CREATE DATABASE Viveros;

-- Eliminar las tablas si ya existen, con CASCADE para eliminar dependencias
DROP TABLE IF EXISTS Producto_Pedido CASCADE;
DROP TABLE IF EXISTS Zona_Producto CASCADE;
DROP TABLE IF EXISTS Historial CASCADE;
DROP TABLE IF EXISTS Pedidos CASCADE;
DROP TABLE IF EXISTS Cliente_Fidelizado CASCADE;
DROP TABLE IF EXISTS Empleado CASCADE;
DROP TABLE IF EXISTS Producto CASCADE;
DROP TABLE IF EXISTS Zona CASCADE;
DROP TABLE IF EXISTS Vivero CASCADE;

-- Creación de la tabla de Vivero
CREATE TABLE Vivero (
    Codigo VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Latitud NUMERIC NOT NULL,
    Longitud NUMERIC NOT NULL,
    Productividad NUMERIC(10, 2) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_nombre_vivero CHECK (Nombre ~ '^[A-Za-z]+( [A-Za-z]+)?$'),
    CONSTRAINT chk_latitud_vivero CHECK (Latitud BETWEEN -90 AND 90),
    CONSTRAINT chk_longitud_vivero CHECK (Longitud BETWEEN -180 AND 180)
);

-- Creación de la tabla de Zona
CREATE TABLE Zona (
    Codigo VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Latitud NUMERIC NOT NULL,
    Longitud NUMERIC NOT NULL,
    Productividad NUMERIC(10, 2) DEFAULT 0 NOT NULL,
    Codigo_Vivero VARCHAR(20) NOT NULL,
    CONSTRAINT fk_vivero_zona FOREIGN KEY (Codigo_Vivero) REFERENCES Vivero(Codigo) ON DELETE CASCADE,
    CONSTRAINT chk_nombre_zona CHECK (Nombre ~ '^[A-Za-z]+( [A-Za-z]+)?$'),
    CONSTRAINT chk_latitud CHECK (Latitud BETWEEN -90 AND 90),
    CONSTRAINT chk_longitud CHECK (Longitud BETWEEN -180 AND 180)
);

-- Creación de la tabla de Producto
CREATE TABLE Producto (
    Codigo VARCHAR(20) PRIMARY KEY,
    Stock INTEGER NOT NULL,
    Precio NUMERIC(10, 2) NOT NULL,
    Costo_Produccion NUMERIC(10, 2) NOT NULL,
    Disponibilidad BOOLEAN NOT NULL,
    CONSTRAINT chk_precio_formato CHECK (Precio >= 0),
    CONSTRAINT chk_costo_formato CHECK (Costo_Produccion >= 0)
);

-- Creación de la tabla de Empleado
CREATE TABLE Empleado (
    DNI VARCHAR(9) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Productividad NUMERIC(10, 2) DEFAULT 0 NOT NULL,  -- Atributo Calculado
    Codigo_Zona VARCHAR(20) NOT NULL,
    Epoca_Año VARCHAR(50) NOT NULL,
    CONSTRAINT fk_zona_empleado FOREIGN KEY (Codigo_Zona) REFERENCES Zona(Codigo) ON DELETE CASCADE,
    CONSTRAINT chk_nombre_formato CHECK (Nombre ~ '^[A-Za-z]+( [A-Za-z]+)?$'),
    CONSTRAINT chk_nombre_no_vacio CHECK (TRIM(Nombre) <> ''),
    CONSTRAINT chk_epoca_año CHECK (Epoca_Año IN ('primavera', 'verano', 'otoño', 'invierno')),
    CONSTRAINT chk_dni_formato CHECK (DNI ~ '^[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKE]$')
);

-- Creación de la tabla Cliente_Fidelizado
CREATE TABLE Cliente_Fidelizado (
    DNI VARCHAR(9) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Bonificaciones NUMERIC(10, 2) DEFAULT 0 NOT NULL,  -- Atributo Calculado
    CONSTRAINT chk_nombre_cliente CHECK (Nombre ~ '^[A-Za-z]+( [A-Za-z]+)?$'),
    CONSTRAINT chk_nombre_cliente_no_vacio CHECK (TRIM(Nombre) <> ''),
    CONSTRAINT chk_dni_formato CHECK (DNI ~ '^[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKE]$')
);

-- Creación de la tabla Pedidos
CREATE TABLE Pedidos (
    Codigo BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Importe NUMERIC(10, 2) DEFAULT 0 NOT NULL,  -- Atributo Calculado
    Fecha VARCHAR(10) NOT NULL,
    DNI_Empleado VARCHAR(9) NOT NULL,
    DNI_ClienteFidelizado VARCHAR(9) NOT NULL,
    CONSTRAINT fk_empleado_pedido FOREIGN KEY (DNI_Empleado) REFERENCES Empleado(DNI) ON DELETE CASCADE,
    CONSTRAINT fk_cliente_pedido FOREIGN KEY (DNI_ClienteFidelizado) REFERENCES Cliente_Fidelizado(DNI) ON DELETE CASCADE,
    CONSTRAINT chk_importe_formato CHECK (Importe >= 0),
    CONSTRAINT chk_fecha_pedido_formato CHECK (Fecha ~ '^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$')
);

-- Creación de la tabla Historial
CREATE TABLE Historial (
    ID_Historial SERIAL PRIMARY KEY,
    Fecha VARCHAR(10) NOT NULL,
    DNI_Empleado VARCHAR(9) NOT NULL,
    Codigo_Zona VARCHAR(20) NOT NULL,
    Codigo_Vivero VARCHAR(20) NOT NULL,
    Epoca_Año VARCHAR(50) NOT NULL,
    Horas_Trabajadas NUMERIC NOT NULL,
    CONSTRAINT fk_empleado_historial FOREIGN KEY (DNI_Empleado) REFERENCES Empleado(DNI) ON DELETE CASCADE,
    CONSTRAINT fk_zona_historial FOREIGN KEY (Codigo_Zona) REFERENCES Zona(Codigo) ON DELETE CASCADE,
    CONSTRAINT fk_vivero_historial FOREIGN KEY (Codigo_Vivero) REFERENCES Vivero(Codigo) ON DELETE CASCADE,
    CONSTRAINT chk_fecha_formato CHECK (Fecha ~ '^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$')
);
-- Creación de la tabla Zona_Producto
CREATE TABLE Zona_Producto (
    Codigo_Producto VARCHAR(20) NOT NULL,
    Codigo_Zona VARCHAR(20) NOT NULL,
    PRIMARY KEY (Codigo_Producto, Codigo_Zona),
    CONSTRAINT fk_producto_zona FOREIGN KEY (Codigo_Producto) REFERENCES Producto(Codigo) ON DELETE CASCADE,
    CONSTRAINT fk_zona_producto FOREIGN KEY (Codigo_Zona) REFERENCES Zona(Codigo) ON DELETE CASCADE
);

-- Creación de la tabla Producto_Pedido
CREATE TABLE Producto_Pedido (
    Codigo_Producto VARCHAR(20) NOT NULL,
    Codigo_Pedido INTEGER NOT NULL,
    Cantidad INTEGER NOT NULL,
    PRIMARY KEY (Codigo_Producto, Codigo_Pedido),
    CONSTRAINT fk_producto_pedido FOREIGN KEY (Codigo_Producto) REFERENCES Producto(Codigo) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_producto FOREIGN KEY (Codigo_Pedido) REFERENCES Pedidos(Codigo) ON DELETE CASCADE
);

-- Vistas
-- Productividad (Empleado, Zona, Vivero)
CREATE VIEW Productividad_Empleado AS
SELECT 
    e.DNI,
    SUM(pp.Cantidad * pr.Precio) AS Productividad
FROM 
    Empleado e
    JOIN Pedidos p ON e.DNI = p.DNI_Empleado
    JOIN Producto_Pedido pp ON p.Codigo = pp.Codigo_Pedido
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
GROUP BY e.DNI;

-- Bonificaciones (Cliente_Fidelizado)
CREATE VIEW Bonificaciones_Cliente AS
SELECT 
    cf.DNI,
    SUM(p.importe) * 0.05 AS Bonificaciones  -- 5% de bonificación sobre el importe total
FROM 
    Cliente_Fidelizado cf
    JOIN Pedidos p ON cf.DNI = p.DNI_ClienteFidelizado
GROUP BY 
    cf.DNI;

-- Importe (Pedidos)
CREATE VIEW Importe_Pedido AS
SELECT 
    p.Codigo,
    SUM(pp.Cantidad * pr.Precio) AS Importe
FROM 
    Pedidos p
    JOIN Producto_Pedido pp ON p.Codigo = pp.Codigo_Pedido
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
GROUP BY 
    p.Codigo;

-- Restricción: Un empleado no puede tener dos destinos en la misma época
ALTER TABLE Historial
ADD CONSTRAINT unica_zona_epoca_empleado UNIQUE (DNI_Empleado, Epoca_Año);

-- Función para verificar que la zona esté en el vivero correcto
CREATE OR REPLACE FUNCTION verificar_zona_vivero()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar que la zona asignada esté en el vivero correcto
    IF EXISTS (
        SELECT 1
        FROM Zona z
        WHERE z.Codigo = NEW.Codigo_Zona
        AND z.Codigo_Vivero <> NEW.Codigo_Vivero
    ) THEN
        RAISE EXCEPTION 'La zona % no pertenece al vivero %', NEW.Codigo_Zona, NEW.Codigo_Vivero;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que llama a la función antes de insertar o actualizar en Historial
CREATE TRIGGER trigger_verificar_zona_vivero
BEFORE INSERT OR UPDATE ON Historial
FOR EACH ROW
EXECUTE FUNCTION verificar_zona_vivero();

-- Función para actualizar la Productividad cada vez que se inserte o actualice un pedido.
CREATE OR REPLACE FUNCTION actualizar_productividad_vivero()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular la productividad total del vivero basándose en los productos vendidos y el coste de producción en sus zonas
    UPDATE Vivero
    SET Productividad = (
        SELECT 
            COALESCE(SUM(pp.Cantidad * pr.Precio), 0) / -- Calcula el valor total de la producción
            COALESCE(SUM(pp.Cantidad * pr.Costo_Produccion), 1)  -- Calcula el coste total de la producción
        FROM Producto_Pedido pp
        JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
        JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
        JOIN Empleado e ON p.DNI_Empleado = e.DNI
        JOIN Zona z ON e.Codigo_Zona = z.Codigo
        WHERE z.Codigo_Vivero = (
            SELECT z.Codigo_Vivero 
            FROM Empleado e
            JOIN Zona z ON e.Codigo_Zona = z.Codigo
            WHERE e.DNI = NEW.DNI_Empleado
        )
    )
    WHERE Codigo = (
        SELECT z.Codigo_Vivero
        FROM Empleado e
        JOIN Zona z ON e.Codigo_Zona = z.Codigo
        WHERE e.DNI = NEW.DNI_Empleado
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que se ejecuta cada vez que se inserte o actualice un pedido
CREATE TRIGGER trigger_actualizar_productividad_vivero
AFTER INSERT OR UPDATE ON Pedidos
FOR EACH ROW
EXECUTE FUNCTION actualizar_productividad_vivero();

-- Función para actualizar el Importe cada vez que se inserte un nuevo pedido o producto asociados a un pedido.
CREATE OR REPLACE FUNCTION actualizar_importe_pedido()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular el importe del pedido basado en los productos y la cantidad
    UPDATE Pedidos
    SET Importe = (
        SELECT SUM(pp.Cantidad * pr.Precio)
        FROM Producto_Pedido pp
        JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
        WHERE pp.Codigo_Pedido = NEW.Codigo_Pedido
    )
    WHERE Codigo = NEW.Codigo_Pedido;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Se ejecuta cada vez que se inserte o actualice un producto
CREATE TRIGGER trigger_actualizar_importe_pedido
AFTER INSERT OR UPDATE ON Producto_Pedido
FOR EACH ROW
EXECUTE FUNCTION actualizar_importe_pedido();

-- Actualizar importes de todos los pedidos
UPDATE Pedidos p
SET Importe = (
    SELECT SUM(pp.Cantidad * pr.Precio)
    FROM Producto_Pedido pp
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
    WHERE pp.Codigo_Pedido = p.Codigo
);

-- Función para actualizar la Productividad de los empleados con base en los productos que vendieron
CREATE OR REPLACE FUNCTION actualizar_productividad_empleado()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular la productividad del empleado basado en los pedidos realizados
    UPDATE Empleado
    SET Productividad = (
        SELECT COALESCE(SUM(pp.Cantidad * pr.Precio), 0)
        FROM Producto_Pedido pp
        JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
        JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
        WHERE p.DNI_Empleado = (
            SELECT p.DNI_Empleado
            FROM Pedidos p
            WHERE p.Codigo = NEW.Codigo_Pedido
        )
    )
    WHERE DNI = (
        SELECT p.DNI_Empleado
        FROM Pedidos p
        WHERE p.Codigo = NEW.Codigo_Pedido
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Se ejecuta cada vez que se inserte o actualice la Productividad de los empleados
CREATE TRIGGER trigger_actualizar_productividad_empleado
AFTER INSERT OR UPDATE ON Producto_Pedido
FOR EACH ROW
EXECUTE FUNCTION actualizar_productividad_empleado();

-- Función para actualizar las bonificaciones de los clientes fidelizados en función de los pedidos que han realizado
CREATE OR REPLACE FUNCTION actualizar_bonificaciones_cliente()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular las bonificaciones del cliente basado en el importe de los pedidos
    UPDATE Cliente_Fidelizado
    SET Bonificaciones = (
        SELECT SUM(p.Importe) * 0.05
        FROM Pedidos p
        WHERE p.DNI_ClienteFidelizado = NEW.DNI_ClienteFidelizado
    )
    WHERE DNI = NEW.DNI_ClienteFidelizado;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Se ejecuta cada vez que se inserte o actualice las bonificaciones de los clientes fidelizados
CREATE TRIGGER trigger_actualizar_bonificaciones_cliente
AFTER INSERT OR UPDATE ON Pedidos
FOR EACH ROW
EXECUTE FUNCTION actualizar_bonificaciones_cliente();

-- 1. Función para actualizar la Productividad de una Zona desde la tabla `Pedidos`
CREATE OR REPLACE FUNCTION actualizar_productividad_zona_pedidos()
RETURNS TRIGGER AS $$
DECLARE
    empleado_zona VARCHAR(20);
BEGIN
    -- Asignar la zona asociada directamente al empleado vinculado al pedido
    SELECT Codigo_Zona INTO empleado_zona
    FROM Empleado
    WHERE DNI = NEW.DNI_Empleado;

    -- Actualizar la productividad de la zona correspondiente al empleado
    UPDATE Zona
    SET Productividad = (
        SELECT 
            COALESCE(SUM(pp.Cantidad * pr.Precio), 0) /  -- Valor total de los productos vendidos
            COALESCE(SUM(pp.Cantidad * pr.Costo_Produccion), 1)  -- Coste total de producción
        FROM Producto_Pedido pp
        JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
        JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
        WHERE p.DNI_Empleado = NEW.DNI_Empleado
    )
    WHERE Codigo = empleado_zona;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Función para actualizar la Productividad de una Zona desde la tabla `Producto_Pedido`
CREATE OR REPLACE FUNCTION actualizar_productividad_zona_producto()
RETURNS TRIGGER AS $$
DECLARE
    empleado_zona VARCHAR(20);
BEGIN
    -- Obtener la zona a partir del pedido relacionado en Producto_Pedido
    SELECT e.Codigo_Zona INTO empleado_zona
    FROM Empleado e
    JOIN Pedidos p ON e.DNI = p.DNI_Empleado
    WHERE p.Codigo = NEW.Codigo_Pedido;

    -- Calcular y actualizar la productividad de la zona
    UPDATE Zona
    SET Productividad = (
        SELECT 
            COALESCE(SUM(pp.Cantidad * pr.Precio), 0) /  -- Valor total de los productos vendidos
            COALESCE(SUM(pp.Cantidad * pr.Costo_Produccion), 1)  -- Coste total de producción
        FROM Producto_Pedido pp
        JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
        WHERE pp.Codigo_Pedido = NEW.Codigo_Pedido
    )
    WHERE Codigo = empleado_zona;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que se ejecuta cada vez que se inserte o actualice un pedido en Pedidos
CREATE TRIGGER trigger_actualizar_productividad_zona_pedidos
AFTER INSERT OR UPDATE ON Pedidos
FOR EACH ROW
EXECUTE FUNCTION actualizar_productividad_zona_pedidos();

-- Trigger que se ejecuta cada vez que se inserte o actualice un producto de un pedido
CREATE TRIGGER trigger_actualizar_productividad_zona_producto
AFTER INSERT OR UPDATE ON Producto_Pedido
FOR EACH ROW
EXECUTE FUNCTION actualizar_productividad_zona_producto();

-- Actualizar la productividad de los empleados
UPDATE Empleado e
SET Productividad = (
    SELECT COALESCE(SUM(pp.Cantidad * pr.Precio), 0)
    FROM Producto_Pedido pp
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
    JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
    WHERE p.DNI_Empleado = e.DNI
);

-- Actualizar las bonificaciones de los clientes fidelizados
UPDATE Cliente_Fidelizado cf
SET Bonificaciones = (
    SELECT COALESCE(SUM(p.Importe) * 0.05, 0)
    FROM Pedidos p
    WHERE p.DNI_ClienteFidelizado = cf.DNI
);

-- Actualizar la productividad de los viveros
UPDATE Vivero v
SET Productividad = (
    SELECT COALESCE(SUM(pp.Cantidad * pr.Precio) / SUM(pp.Cantidad * pr.Costo_Produccion), 0)
    FROM Producto_Pedido pp
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
    JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
    JOIN Empleado e ON p.DNI_Empleado = e.DNI
    JOIN Zona z ON e.Codigo_Zona = z.Codigo
    WHERE z.Codigo_Vivero = v.Codigo
);

-- Ejemplo de corrección en una consulta de actualización:
UPDATE Zona z
SET Productividad = (
    SELECT 
        COALESCE(SUM(pp.Cantidad * pr.Precio), 0) /  -- Valor total de los productos vendidos
        COALESCE(SUM(pp.Cantidad * pr.Costo_Produccion), 1)  -- Coste total de producción
    FROM Producto_Pedido pp
    JOIN Producto pr ON pp.Codigo_Producto = pr.Codigo
    JOIN Pedidos p ON pp.Codigo_Pedido = p.Codigo
    JOIN Empleado e ON p.DNI_Empleado = e.DNI
    WHERE e.Codigo_Zona = z.Codigo
);

-- Inserts para la tabla Vivero
INSERT INTO Vivero (Codigo, Nombre, Latitud, Longitud, Productividad)
VALUES 
    ('VIV001', 'ViveroNorte', 28.12345, -15.23456, 0),
    ('VIV002', 'ViveroSur', 27.98765, -16.54321, 0),
    ('VIV003', 'ViveroEste', 28.45678, -15.87654, 0),
    ('VIV004', 'ViveroOeste', 29.23456, -14.12345, 0),
    ('VIV005', 'ViveroCentral', 30.54321, -13.98765, 0);

-- Inserts para la tabla Zona
INSERT INTO Zona (Codigo, Nombre, Latitud, Longitud, Productividad, Codigo_Vivero)
VALUES 
    ('ZON001', 'ZonaA', 28.12346, -15.23457, 0, 'VIV001'),
    ('ZON002', 'ZonaB', 27.98766, -16.54322, 0, 'VIV002'),
    ('ZON003', 'ZonaC', 28.45679, -15.87655, 0, 'VIV003'),
    ('ZON004', 'ZonaD', 29.23457, -14.12346, 0, 'VIV004'),
    ('ZON005', 'ZonaE', 30.54322, -13.98766, 0, 'VIV005');

-- Inserts para la tabla Producto
INSERT INTO Producto (Codigo, Stock, Precio, Costo_Produccion, Disponibilidad)
VALUES 
    ('PROD001', 100, 20.00, 10.00, TRUE),
    ('PROD002', 200, 15.50, 8.50, TRUE),
    ('PROD003', 150, 30.00, 18.00, FALSE),
    ('PROD004', 50, 45.00, 22.50, TRUE),
    ('PROD005', 80, 12.00, 6.00, FALSE);

-- Inserts para la tabla Empleado con DNIs válidos
INSERT INTO Empleado (DNI, Nombre, Productividad, Codigo_Zona, Epoca_Año)
VALUES 
    ('12345678Z', 'Juan Perez', 0, 'ZON001', 'verano'),  -- Z es la letra correcta para 12345678
    ('87654321M', 'Maria Gomez', 0, 'ZON002', 'invierno'), -- M es la letra correcta para 87654321
    ('11223344X', 'Carlos Ramirez', 0, 'ZON003', 'primavera'), -- X es la letra correcta para 11223344
    ('33445566Y', 'Ana Garcia', 0, 'ZON004', 'otoño'), -- Y es la letra correcta para 33445566
    ('55667788S', 'Luis Fernandez', 0, 'ZON005', 'verano'); -- S es la letra correcta para 55667788

-- Inserts para la tabla Cliente_Fidelizado con DNIs válidos
INSERT INTO Cliente_Fidelizado (DNI, Nombre, Bonificaciones)
VALUES 
    ('23456789A', 'Ana Lopez', 0),   -- A es la letra correcta para 23456789
    ('98765432P', 'Pedro Sanchez', 0), -- P es la letra correcta para 98765432
    ('34567890T', 'Laura Garcia', 0),  -- T es la letra correcta para 34567890
    ('45678901R', 'Jose Martinez', 0), -- R es la letra correcta para 45678901
    ('56789012Q', 'Rosa Ruiz', 0);     -- Q es la letra correcta para 56789012

-- Inserts para la tabla Pedidos
INSERT INTO Pedidos (Fecha, DNI_Empleado, DNI_ClienteFidelizado, Importe)
VALUES 
    ('15/08/2024', '12345678Z', '23456789A', 0),
    ('16/08/2024', '87654321M', '98765432P', 0),
    ('17/08/2024', '11223344X', '34567890T', 0),
    ('18/08/2024', '33445566Y', '45678901R', 0),
    ('19/08/2024', '55667788S', '56789012Q', 0);

-- Inserts para la tabla Producto_Pedido
INSERT INTO Producto_Pedido (Codigo_Producto, Codigo_Pedido, Cantidad)
VALUES 
    ('PROD001', 1, 5),
    ('PROD002', 2, 10),
    ('PROD003', 3, 7),
    ('PROD004', 4, 3),
    ('PROD005', 5, 8);

-- Inserts para la tabla Historial
INSERT INTO Historial (Fecha, DNI_Empleado, Codigo_Zona, Codigo_Vivero, Epoca_Año, Horas_Trabajadas)
VALUES 
    ('01/06/2024', '12345678Z', 'ZON001', 'VIV001', 'verano', 8),
    ('02/06/2024', '87654321M', 'ZON002', 'VIV002', 'invierno', 6),
    ('03/06/2024', '11223344X', 'ZON003', 'VIV003', 'primavera', 7),
    ('04/06/2024', '33445566Y', 'ZON004', 'VIV004', 'otoño', 5),
    ('05/06/2024', '55667788S', 'ZON005', 'VIV005', 'verano', 4);

-- Inserts para la tabla Zona_Producto
INSERT INTO Zona_Producto (Codigo_Producto, Codigo_Zona)
VALUES 
    ('PROD001', 'ZON001'),
    ('PROD002', 'ZON002'),
    ('PROD003', 'ZON003'),
    ('PROD004', 'ZON004'),
    ('PROD005', 'ZON005');

-- Consultas para visualizar el contenido de todas las tablas
-- Ver todos los viveros
SELECT 'Vivero' AS Vivero, * FROM Vivero;
-- Ver todas las zonas y su vivero asociado
SELECT 'Zona' AS Zona, * FROM Zona;
-- Ver todos los productos
SELECT 'Producto' AS Producto, * FROM Producto;
-- Ver todos los empleados y la zona en la que trabajan
SELECT 'Empleado' AS Empleado, * FROM Empleado;
-- Ver todos los clientes fidelizados y sus bonificaciones
SELECT 'Cliente_Fidelizado' AS "Cliente Fidelizado", * FROM Cliente_Fidelizado;
-- Ver todos los pedidos con detalles del empleado y cliente
SELECT 'Pedidos' AS Pedidos, * FROM Pedidos;
-- Ver el historial de empleados por zona y vivero
SELECT 'Historial' AS Historial, * FROM Historial;
-- Ver productos asociados a cada zona
SELECT 'Zona_Producto' AS "Zona-Producto", * FROM Zona_Producto;
-- Ver productos pedidos en cada pedido
SELECT 'Producto_Pedido' AS "Producto-Pedido", * FROM Producto_Pedido;

-- Ejemplo de DELETE en las tablas
-- Elimina registros de la tabla Vivero
DELETE FROM Vivero WHERE Codigo = 'VIV001';
-- Elimina registros de la tabla Producto
DELETE FROM Producto WHERE Codigo = 'PROD001';
-- Elimina registros de la tabla Empleado
DELETE FROM Empleado WHERE DNI = '12345678Z';
-- Elimina registros de la tabla Pedidos
DELETE FROM Pedidos WHERE Fecha = '19/08/2024';
-- Elimina registros de la tabla Cliente_Fidelizado
DELETE FROM Cliente_Fidelizado WHERE DNI = '23456789A';

-- Consultas para visualizar el contenido de todas las tablas
-- Ver todos los viveros
SELECT 'Vivero' AS Vivero, * FROM Vivero;
-- Ver todas las zonas y su vivero asociado
SELECT 'Zona' AS Zona, * FROM Zona;
-- Ver todos los productos
SELECT 'Producto' AS Producto, * FROM Producto;
-- Ver todos los empleados y la zona en la que trabajan
SELECT 'Empleado' AS Empleado, * FROM Empleado;
-- Ver todos los clientes fidelizados y sus bonificaciones
SELECT 'Cliente_Fidelizado' AS "Cliente Fidelizado", * FROM Cliente_Fidelizado;
-- Ver todos los pedidos con detalles del empleado y cliente
SELECT 'Pedidos' AS Pedidos, * FROM Pedidos;
-- Ver el historial de empleados por zona y vivero
SELECT 'Historial' AS Historial, * FROM Historial;
-- Ver productos asociados a cada zona
SELECT 'Zona_Producto' AS "Zona-Producto", * FROM Zona_Producto;
-- Ver productos pedidos en cada pedido
SELECT 'Producto_Pedido' AS "Producto-Pedido", * FROM Producto_Pedido;
