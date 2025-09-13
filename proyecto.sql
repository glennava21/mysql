DROP DATABASE IF EXISTS coworking_db;
CREATE DATABASE coworking_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE coworking_db;

-- Activar el planificador de eventos para versiones de MySQL
SET GLOBAL event_scheduler = ON;

-- ============================================================
-- TABLAS PRINCIPALES
-- ============================================================
-- Empresas
CREATE TABLE empresas (
  empresa_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  direccion VARCHAR(300),
  telefono VARCHAR(50),
  email VARCHAR(150),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Usuarios
CREATE TABLE usuarios (
  usuario_id INT AUTO_INCREMENT PRIMARY KEY,
  identificacion VARCHAR(50) UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100),
  fecha_nacimiento DATE,
  email VARCHAR(150),
  telefono VARCHAR(50),
  empresa_id INT NULL,
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  ultimo_acceso TIMESTAMP NULL,
  FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Tipos de membresía
CREATE TABLE membresias_tipo (
  tipo_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  duracion_dias INT NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  descripcion VARCHAR(300)
) ENGINE=InnoDB;

-- Membresías asignadas a usuarios (historial)
CREATE TABLE usuario_membresias (
  usuario_membresia_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  tipo_id INT NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  estado ENUM('Activa','Suspendida','Vencida') DEFAULT 'Activa',
  renovaciones INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  FOREIGN KEY (tipo_id) REFERENCES membresias_tipo(tipo_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- ESPACIOS Y RESERVAS
-- ============================================================
-- Espacios físicos
CREATE TABLE espacios (
  espacio_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  tipo ENUM('Escritorio','Oficina','SalaReuniones','SalaEventos') NOT NULL,
  capacidad INT NOT NULL DEFAULT 1,
  descripcion VARCHAR(300),
  horario_inicio TIME DEFAULT '08:00:00',
  horario_fin TIME DEFAULT '20:00:00',
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Reservas de espacios (sin columna calculada)
CREATE TABLE reservas (
  reserva_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  espacio_id INT NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NOT NULL,
  duracion_horas DECIMAL(6,2),
  estado ENUM('Pendiente','Confirmada','Cancelada','NoShow') DEFAULT 'Pendiente',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  asistentes INT DEFAULT 1,
  empresa_factura_id INT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  FOREIGN KEY (espacio_id) REFERENCES espacios(espacio_id) ON DELETE CASCADE,
  FOREIGN KEY (empresa_factura_id) REFERENCES empresas(empresa_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- SERVICIOS
-- ============================================================
-- Servicios extra
CREATE TABLE servicios (
  servicio_id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion VARCHAR(300),
  precio DECIMAL(10,2) DEFAULT 0.00,
  activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Servicios asignados a usuario
CREATE TABLE usuario_servicios (
  usuario_id INT,
  servicio_id INT,
  activo BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (usuario_id, servicio_id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  FOREIGN KEY (servicio_id) REFERENCES servicios(servicio_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Servicios incluidos en reservas
CREATE TABLE reserva_servicios (
  reserva_id INT NOT NULL,
  servicio_id INT NOT NULL,
  cantidad INT DEFAULT 1,
  PRIMARY KEY (reserva_id, servicio_id),
  FOREIGN KEY (reserva_id) REFERENCES reservas(reserva_id) ON DELETE CASCADE,
  FOREIGN KEY (servicio_id) REFERENCES servicios(servicio_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- FACTURACIÓN Y PAGOS
-- ============================================================
-- Facturas
CREATE TABLE facturas (
  factura_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  empresa_id INT NULL,
  tipo VARCHAR(50),
  monto_total DECIMAL(12,2) NOT NULL,
  estado ENUM('Pendiente','Pagada','Cancelada') DEFAULT 'Pendiente',
  fecha_vencimiento DATE,
  saldo_pendiente DECIMAL(12,2) DEFAULT 0.00,
  referencia VARCHAR(120),
  emitida_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Pagos
CREATE TABLE pagos (
  pago_id INT AUTO_INCREMENT PRIMARY KEY,
  factura_id INT NOT NULL,
  usuario_id INT NOT NULL,
  metodo ENUM('Efectivo','Tarjeta','Transferencia','PayPal'),
  monto DECIMAL(12,2) NOT NULL,
  estado ENUM('Pendiente','Pagado','Fallido') DEFAULT 'Pendiente',
  referencia_transaccion VARCHAR(255),
  fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (factura_id) REFERENCES facturas(factura_id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- SEGURIDAD Y LOGS
-- ============================================================
-- Registros de acceso
CREATE TABLE registros_acceso (
  acceso_id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  tipo_acceso ENUM('Entrada','Salida') NOT NULL,
  metodo ENUM('RFID','QR','Manual') NOT NULL,
  estado VARCHAR(20) DEFAULT 'Aceptado',
  motivo_rechazo VARCHAR(255),
  fecha_hora_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Accesos fallidos
CREATE TABLE accesos_fallidos (
  fallo_id INT AUTO_INCREMENT PRIMARY KEY,
  identificador VARCHAR(150),
  razon VARCHAR(255),
  fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Auditoría
CREATE TABLE auditoria (
  auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
  entidad VARCHAR(50),
  entidad_id INT,
  accion VARCHAR(50),
  usuario_ejecutor INT NULL,
  detalles TEXT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_ejecutor) REFERENCES usuarios(usuario_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Tabla de logs para auditoría
CREATE TABLE logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  nivel ENUM('INFO','WARN','ERROR','AUDIT') NOT NULL,
  categoria VARCHAR(100),
  mensaje TEXT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ============================================================
CREATE INDEX idx_usuario_empresa ON usuarios (empresa_id);
CREATE INDEX idx_reserva_espacio_fecha ON reservas (espacio_id, fecha_inicio, fecha_fin);
CREATE INDEX idx_factura_estado ON facturas (estado);
CREATE INDEX idx_pago_metodo ON pagos (metodo);
CREATE INDEX idx_usuario_membresias_estado ON usuario_membresias(estado);
CREATE INDEX idx_usuario_membresias_fecha ON usuario_membresias(fecha_fin);
CREATE INDEX idx_reservas_fecha ON reservas(fecha_inicio);
CREATE INDEX idx_accesos_usuario_fecha ON registros_acceso(usuario_id, fecha_hora_acceso);

-- ============================================================
-- DATOS DE PRUEBA COMPLETOS (en orden correcto)
-- ============================================================
-- Empresas
INSERT INTO empresas (nombre, direccion, telefono, email) VALUES
('TechCorp', 'Av. Siempre Viva 101', '555-1000', 'contacto@techcorp.com'),
('Innova SA', 'Calle Luna 202', '555-2000', 'info@innova.com'),
('StartUpX', 'Calle Sol 303', '555-3000', 'hello@startupx.com'),
('Corporación XYZ', 'Av. Principal 404', '555-4000', 'info@xyz.com'),
('Empresa Grande SA', 'Calle Grande 505', '555-5000', 'contacto@empresagrande.com');

-- Usuarios
INSERT INTO usuarios (identificacion, nombre, apellidos, fecha_nacimiento, email, telefono, empresa_id) VALUES
('11111111', 'Juan', 'Pérez', '1990-05-10', 'juan@correo.com', '555-1111', 1),
('22222222', 'Ana', 'García', '1985-07-22', 'ana@correo.com', '555-2222', 1),
('33333333', 'Luis', 'Torres', '1992-11-30', 'luis@correo.com', '555-3333', 2),
('44444444', 'Maria', 'López', '1995-01-15', 'maria@correo.com', '555-4444', NULL),
('55555555', 'Pedro', 'Martínez', '1988-03-25', 'pedro@correo.com', '555-5555', NULL),
('66666666', 'Carlos', 'Rodríguez', '1988-09-15', 'carlos@correo.com', '555-6666', 1),
('77777777', 'Laura', 'Gómez', '1993-04-18', 'laura@correo.com', '555-7777', 3),
('88888888', 'Miguel', 'Sánchez', '1987-12-05', 'miguel@correo.com', '555-8888', 2),
('99999999', 'Elena', 'Díaz', '1991-08-22', 'elena@correo.com', '555-9999', 4),
('10101010', 'Roberto', 'Fernández', '1989-06-30', 'roberto@correo.com', '555-1010', 5);

-- Tipos de membresía
INSERT INTO membresias_tipo (nombre, duracion_dias, precio, descripcion) VALUES
('Diaria', 1, 10.00, 'Acceso por día'),
('Mensual Básica', 30, 100.00, 'Acceso a escritorios compartidos'),
('Mensual Premium', 30, 200.00, 'Acceso a oficinas privadas y salas'),
('Trimestral', 90, 250.00, 'Acceso por 3 meses'),
('Anual Corporativa', 365, 1000.00, 'Acceso total anual'),
('Corporativa', 365, 1500.00, 'Membresía corporativa con descuentos');

-- Membresías de usuarios
INSERT INTO usuario_membresias (usuario_id, tipo_id, fecha_inicio, fecha_fin, estado, renovaciones) VALUES
(1, 2, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Activa', 2),
(2, 3, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Activa', 1),
(3, 5, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Activa', 0),
(4, 2, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'Suspendida', 0),
(5, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'Activa', 5),
(6, 3, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Activa', 0),
(7, 4, '2024-01-01', '2024-03-31', 'Vencida', 0),
(8, 6, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Activa', 0),
(9, 6, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Activa', 0),
(10, 3, DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'Activa', 1);

-- Espacios
INSERT INTO espacios (nombre, tipo, capacidad, descripcion) VALUES
('Escritorio A1', 'Escritorio', 1, 'Espacio individual'),
('Escritorio A2', 'Escritorio', 1, 'Espacio individual'),
('Oficina B1', 'Oficina', 4, 'Oficina privada'),
('Oficina B2', 'Oficina', 6, 'Oficina privada grande'),
('Sala Reuniones 1', 'SalaReuniones', 10, 'Sala de reuniones'),
('Sala Reuniones 2', 'SalaReuniones', 8, 'Sala de reuniones pequeña'),
('Auditorio X', 'SalaEventos', 50, 'Espacio para eventos'),
('Sala Conferencias', 'SalaEventos', 30, 'Sala para conferencias');

-- Servicios
INSERT INTO servicios (nombre, descripcion, precio) VALUES
('Locker', 'Alquiler de casillero', 20.00),
('Impresiones', 'Servicio de impresión por página', 0.10),
('Café Ilimitado', 'Acceso a café durante la estancia', 15.00),
('Parking', 'Estacionamiento reservado', 10.00),
('Videoconferencia', 'Equipo de videoconferencia', 25.00);

-- Reservas (con cálculo manual de duración)
INSERT INTO reservas (usuario_id, espacio_id, fecha_inicio, fecha_fin, duracion_horas, estado, asistentes) VALUES
(2, 3, NOW(), DATE_ADD(NOW(), INTERVAL 2 HOUR), 2.0, 'Confirmada', 3),
(6, 5, DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 4 HOUR), 3.0, 'Confirmada', 8),
(10, 4, DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 6 HOUR), 4.0, 'Confirmada', 5),
(3, 6, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 2 HOUR), 3.0, 'Confirmada', 6),
(8, 7, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 5 HOUR), 5.0, 'Confirmada', 25),
(4, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 2 HOUR), 1.0, 'Cancelada', 1),
(5, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 0 HOUR), 2.0, 'NoShow', 1),
(9, 8, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_ADD(NOW(), INTERVAL 3 HOUR), 3.0, 'Pendiente', 15),
(1, 2, DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 2 HOUR), 2.0, 'Confirmada', 1),
(6, 3, DATE_ADD(NOW(), INTERVAL 6 DAY), DATE_ADD(NOW(), INTERVAL 4 HOUR), 4.0, 'Pendiente', 4);

-- Servicios de usuarios
INSERT INTO usuario_servicios VALUES
(1, 1, TRUE), (2, 2, TRUE), (3, 3, TRUE), (6, 4, TRUE), (8, 5, TRUE),
(2, 3, TRUE), (6, 2, TRUE), (10, 1, TRUE), (9, 5, TRUE);

-- Servicios en reservas
INSERT INTO reserva_servicios (reserva_id, servicio_id, cantidad) VALUES
(1, 2, 50), (2, 3, 1), (3, 4, 2), (4, 1, 1), (5, 5, 1),
(6, 2, 30), (7, 3, 2), (8, 4, 1), (9, 5, 1), (10, 1, 1);

-- Facturas
INSERT INTO facturas (usuario_id, empresa_id, tipo, monto_total, estado, fecha_vencimiento, saldo_pendiente, referencia) VALUES
(1, 1, 'Membresia', 100.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-001'),
(2, 1, 'Membresia', 200.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-002'),
(3, 2, 'Membresia', 150.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-003'),
(6, 1, 'Membresia', 200.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-007'),
(10, NULL, 'Membresia', 200.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-010'),
(4, NULL, 'Servicio', 50.00, 'Pendiente', DATE_SUB(CURDATE(), INTERVAL 5 DAY), 50.00, 'FAC-004'),
(5, NULL, 'Servicio', 75.00, 'Pendiente', DATE_SUB(CURDATE(), INTERVAL 10 DAY), 75.00, 'FAC-005'),
(7, 3, 'Membresia', 250.00, 'Pendiente', DATE_SUB(CURDATE(), INTERVAL 15 DAY), 250.00, 'FAC-008'),
(2, 1, 'Reserva', 250.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-005'),
(2, 1, 'Reserva', 300.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-006'),
(6, 1, 'Reserva', 180.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0.00, 'FAC-009'),
(8, 4, 'Consolidada', 1200.00, 'Pendiente', DATE_ADD(CURDATE(), INTERVAL 30 DAY), 1200.00, 'FC-001'),
(9, 5, 'Consolidada', 1500.00, 'Pagada', DATE_ADD(CURDATE(), INTERVAL 30 DAY), 0.00, 'FC-002');

-- Pagos
INSERT INTO pagos (factura_id, usuario_id, metodo, monto, estado, referencia_transaccion) VALUES
(1, 1, 'Tarjeta', 100.00, 'Pagado', 'TX-001'),
(2, 2, 'Transferencia', 200.00, 'Pagado', 'TX-002'),
(3, 3, 'Efectivo', 150.00, 'Pagado', 'TX-003'),
(9, 2, 'PayPal', 250.00, 'Pagado', 'TX-005'),
(10, 2, 'Transferencia', 300.00, 'Pagado', 'TX-006'),
(4, 6, 'Tarjeta', 200.00, 'Pagado', 'TX-007'),
(11, 6, 'PayPal', 180.00, 'Pagado', 'TX-009'),
(5, 10, 'Transferencia', 200.00, 'Pagado', 'TX-010'),
(13, 9, 'Tarjeta', 1500.00, 'Pagado', 'TX-012'),
(6, 4, 'PayPal', 50.00, 'Pendiente', 'TX-004'),
(8, 7, 'Transferencia', 250.00, 'Fallido', 'TX-008'),
(12, 8, 'Tarjeta', 600.00, 'Pendiente', 'TX-011');

-- Registros de acceso
INSERT INTO registros_acceso (usuario_id, tipo_acceso, metodo, estado, fecha_hora_acceso, motivo_rechazo) VALUES
(2, 'Entrada', 'RFID', 'Aceptado', NOW(), NULL),
(6, 'Entrada', 'QR', 'Aceptado', NOW(), NULL),
(10, 'Entrada', 'Manual', 'Aceptado', NOW(), NULL),
(2, 'Salida', 'RFID', 'Aceptado', DATE_ADD(NOW(), INTERVAL 2 HOUR), NULL),
(1, 'Entrada', 'RFID', 'Aceptado', DATE_SUB(NOW(), INTERVAL 1 DAY), NULL),
(1, 'Salida', 'RFID', 'Aceptado', DATE_SUB(NOW(), INTERVAL 23 HOUR), NULL),
(3, 'Entrada', 'QR', 'Aceptado', DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(3, 'Salida', 'QR', 'Aceptado', DATE_SUB(NOW(), INTERVAL 21 HOUR), NULL),
(6, 'Entrada', 'Manual', 'Aceptado', CONCAT(CURDATE(), ' 07:30:00'), NULL),
(6, 'Salida', 'Manual', 'Aceptado', CONCAT(CURDATE(), ' 21:15:00'), NULL),
(4, 'Entrada', 'RFID', 'Rechazado', NOW(), 'Membresía suspendida'),
(7, 'Entrada', 'QR', 'Rechazado', NOW(), 'Membresía vencida');

-- Accesos fallidos
INSERT INTO accesos_fallidos (identificador, razon) VALUES
('tarjeta-xyz', 'Tarjeta inválida'),
('usuario@fake.com', 'Usuario inexistente'),
('QR-damaged', 'Código QR dañado'),
('RFID-12345', 'Tarjeta no registrada');

-- Auditoría (usando TEXT en lugar de JSON para mayor compatibilidad)
INSERT INTO auditoria (entidad, entidad_id, accion, usuario_ejecutor, detalles) VALUES
('usuarios', 1, 'CREACION', 1, '{"email": "juan@correo.com"}'),
('reservas', 1, 'CREACION', 1, '{"espacio": "Escritorio A1"}'),
('pagos', 1, 'PAGO', 1, '{"monto": 100, "metodo": "Tarjeta"}'),
('facturas', 4, 'ANULACION', 1, '{"motivo": "Pago duplicado"}'),
('usuarios', 6, 'ACTUALIZACION', 1, '{"campo": "telefono", "valor": "555-6666"}');

-- Logs
INSERT INTO logs (nivel, categoria, mensaje) VALUES
('INFO', 'Sistema', 'Base de datos inicializada'),
('INFO', 'Reserva', 'Reserva 1 creada para usuario 2'),
('WARN', 'Acceso', 'Intento de acceso rechazado para usuario 4'),
('AUDIT', 'Pago', 'Pago procesado TX-001');

-- ============================================================
-- TRIGGERS (con DELIMITER para evitar problemas)
-- ============================================================
DELIMITER $$

-- Trigger 1: Insertar fecha de vencimiento automáticamente
CREATE TRIGGER trg_membresia_fecha_vencimiento
BEFORE INSERT ON usuario_membresias
FOR EACH ROW
BEGIN
    DECLARE duracion INT;
    SELECT duracion_dias INTO duracion FROM membresias_tipo WHERE tipo_id = NEW.tipo_id;
    SET NEW.fecha_fin = DATE_ADD(NEW.fecha_inicio, INTERVAL duracion DAY);
END$$

-- Trigger 2: Calcular duración al insertar reserva
CREATE TRIGGER trg_calcular_duracion_insert
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
    SET NEW.duracion_horas = TIMESTAMPDIFF(HOUR, NEW.fecha_inicio, NEW.fecha_fin);
END$$

-- Trigger 3: Calcular duración al actualizar reserva
CREATE TRIGGER trg_calcular_duracion_update
BEFORE UPDATE ON reservas
FOR EACH ROW
BEGIN
    SET NEW.duracion_horas = TIMESTAMPDIFF(HOUR, NEW.fecha_inicio, NEW.fecha_fin);
END$$

DELIMITER ;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS (con DELIMITER)
-- ============================================================
DELIMITER $$

-- Procedimiento para registrar nueva membresía
CREATE PROCEDURE registrar_nueva_membresia(
    IN p_usuario_id INT,
    IN p_tipo_id INT,
    IN p_fecha_inicio DATE
)
BEGIN
    INSERT INTO usuario_membresias (usuario_id, tipo_id, fecha_inicio)
    VALUES (p_usuario_id, p_tipo_id, p_fecha_inicio);
    
    SELECT 'Membresía registrada correctamente' AS resultado;
END$$

-- Procedimiento para renovar membresía
CREATE PROCEDURE renovar_membresia(
    IN p_usuario_membresia_id INT
)
BEGIN
    DECLARE v_tipo_id INT;
    DECLARE v_duracion INT;
    
    SELECT tipo_id INTO v_tipo_id 
    FROM usuario_membresias 
    WHERE usuario_membresia_id = p_usuario_membresia_id;
    
    SELECT duracion_dias INTO v_duracion 
    FROM membresias_tipo 
    WHERE tipo_id = v_tipo_id;
    
    UPDATE usuario_membresias
    SET fecha_inicio = CURDATE(),
        fecha_fin = DATE_ADD(CURDATE(), INTERVAL v_duracion DAY),
        estado = 'Activa',
        renovaciones = renovaciones + 1
    WHERE usuario_membresia_id = p_usuario_membresia_id;
    
    SELECT 'Membresía renovada correctamente' AS resultado;
END$$

DELIMITER ;

-- ============================================================
-- ROLES Y PERMISOS
-- ============================================================
-- Crear roles
CREATE ROLE IF NOT EXISTS 'coworking_admin';
CREATE ROLE IF NOT EXISTS 'coworking_recepcionista'; 
CREATE ROLE IF NOT EXISTS 'coworking_usuario';
CREATE ROLE IF NOT EXISTS 'coworking_gerente_corp';
CREATE ROLE IF NOT EXISTS 'coworking_contador';

-- Asignar permisos
GRANT ALL PRIVILEGES ON coworking_db.* TO 'coworking_admin';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuarios TO 'coworking_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario_membresias TO 'coworking_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.empresas TO 'coworking_recepcionista';
GRANT SELECT, INSERT, UPDATE, DELETE ON coworking_db.reservas TO 'coworking_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.espacios TO 'coworking_recepcionista';
GRANT SELECT, INSERT ON coworking_db.registros_acceso TO 'coworking_recepcionista';
GRANT SELECT, INSERT ON coworking_db.accesos_fallidos TO 'coworking_recepcionista';
GRANT SELECT ON coworking_db.servicios TO 'coworking_recepcionista';
GRANT SELECT ON coworking_db.facturas TO 'coworking_recepcionista';

GRANT SELECT ON coworking_db.usuarios TO 'coworking_usuario';
GRANT SELECT ON coworking_db.usuario_membresias TO 'coworking_usuario';
GRANT SELECT, INSERT, UPDATE, DELETE ON coworking_db.reservas TO 'coworking_usuario';
GRANT SELECT ON coworking_db.espacios TO 'coworking_usuario';
GRANT SELECT ON coworking_db.facturas TO 'coworking_usuario';
GRANT SELECT ON coworking_db.registros_acceso TO 'coworking_usuario';

GRANT SELECT, INSERT, UPDATE ON coworking_db.usuarios TO 'coworking_gerente_corp';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario_membresias TO 'coworking_gerente_corp';
GRANT SELECT, INSERT, UPDATE, DELETE ON coworking_db.reservas TO 'coworking_gerente_corp';
GRANT SELECT ON coworking_db.facturas TO 'coworking_gerente_corp';
GRANT SELECT ON coworking_db.pagos TO 'coworking_gerente_corp';
GRANT SELECT ON coworking_db.registros_acceso TO 'coworking_gerente_corp';

GRANT SELECT ON coworking_db.* TO 'coworking_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.facturas TO 'coworking_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.pagos TO 'coworking_contador';
GRANT SELECT ON coworking_db.usuario_membresias TO 'coworking_contador';
GRANT SELECT ON coworking_db.reservas TO 'coworking_contador';
GRANT SELECT ON coworking_db.servicios TO 'coworking_contador';

-- ============================================================
-- CREACIÓN DE USUARIOS EJEMPLO
-- ============================================================
CREATE USER 'admin_coworking'@'localhost' IDENTIFIED BY 'Admin123!';
GRANT 'coworking_admin' TO 'admin_coworking'@'localhost';
SET DEFAULT ROLE 'coworking_admin' TO 'admin_coworking'@'localhost';

CREATE USER 'recepcion'@'localhost' IDENTIFIED BY 'Recepcion123!';
GRANT 'coworking_recepcionista' TO 'recepcion'@'localhost';
SET DEFAULT ROLE 'coworking_recepcionista' TO 'recepcion'@'localhost';

CREATE USER 'usuario_ejemplo'@'localhost' IDENTIFIED BY 'Usuario123!';
GRANT 'coworking_usuario' TO 'usuario_ejemplo'@'localhost';
SET DEFAULT ROLE 'coworking_usuario' TO 'usuario_ejemplo'@'localhost';

CREATE USER 'gerente_abc'@'localhost' IDENTIFIED BY 'Gerente123!';
GRANT 'coworking_gerente_corp' TO 'gerente_abc'@'localhost';
SET DEFAULT ROLE 'coworking_gerente_corp' TO 'gerente_abc'@'localhost';

CREATE USER 'contador'@'localhost' IDENTIFIED BY 'Contador123!';
GRANT 'coworking_contador' TO 'contador'@'localhost';
SET DEFAULT ROLE 'coworking_contador' TO 'contador'@'localhost';


-- 1. Listar todos los usuarios con información de su empresa
SELECT u.usuario_id, u.identificacion, u.nombre, u.apellidos, u.email, u.telefono, e.nombre AS empresa
FROM usuarios u LEFT JOIN empresas e ON u.empresa_id = e.empresa_id;

-- 2. Listar los usuarios con membresía activa
SELECT DISTINCT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Activa';

-- 3. Listar los usuarios cuya membresía está vencida
SELECT DISTINCT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Vencida';

-- 4. Listar los usuarios con membresía suspendida
SELECT DISTINCT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Suspendida';

-- 5. Contar cuántos usuarios tienen cada tipo de membresía
SELECT mt.nombre AS tipo_membresia, COUNT(DISTINCT um.usuario_id) AS cantidad_usuarios
FROM usuario_membresias um
JOIN membresias_tipo mt ON um.tipo_id = mt.tipo_id
GROUP BY mt.tipo_id, mt.nombre;

-- 6. Mostrar el top 10 de usuarios con más antigüedad en el coworking
SELECT usuario_id, nombre, apellidos, fecha_registro
FROM usuarios
ORDER BY fecha_registro ASC
LIMIT 10;

-- 7. Listar usuarios que pertenecen a una empresa específica (empresa_id = 2)
SELECT u.* FROM usuarios u WHERE u.empresa_id = 2;

-- 8. Contar cuántos usuarios están asociados a cada empresa
SELECT e.empresa_id, e.nombre, COUNT(u.usuario_id) AS cantidad
FROM empresas e LEFT JOIN usuarios u ON e.empresa_id = u.empresa_id
GROUP BY e.empresa_id, e.nombre;

-- 9. Mostrar usuarios que nunca han hecho una reserva
SELECT u.*
FROM usuarios u
LEFT JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.reserva_id IS NULL;

-- 10. Mostrar usuarios con más de 5 reservas activas en el mes
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(r.reserva_id) AS reservas_mes
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado IN ('Pendiente','Confirmada')
AND YEAR(r.fecha_inicio) = YEAR(CURDATE())
AND MONTH(r.fecha_inicio) = MONTH(CURDATE())
GROUP BY u.usuario_id
HAVING COUNT(r.reserva_id) > 5;

-- 11. Calcular el promedio de edad de los usuarios
SELECT AVG(TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE())) AS edad_promedio
FROM usuarios;

-- 12. Listar usuarios que han cambiado de membresía más de 2 veces
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(um.usuario_membresia_id) AS cambios_membresia
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
GROUP BY u.usuario_id
HAVING COUNT(um.usuario_membresia_id) > 2;

-- 13. Listar usuarios que han gastado más de $500 en reservas
SELECT u.usuario_id, u.nombre, u.apellidos, SUM(f.monto_total) AS total_gastado
FROM usuarios u
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.tipo = 'Reserva' AND f.estado = 'Pagada'
GROUP BY u.usuario_id
HAVING SUM(f.monto_total) > 500;

-- 14. Mostrar usuarios que tienen tanto membresía como servicios adicionales
SELECT DISTINCT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
JOIN usuario_servicios us ON u.usuario_id = us.usuario_id
WHERE um.estado = 'Activa' AND us.activo = TRUE;

-- 15. Listar usuarios con membresía Premium y reservas activas
SELECT DISTINCT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
JOIN membresias_tipo mt ON um.tipo_id = mt.tipo_id
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE mt.nombre LIKE '%Premium%' 
AND um.estado = 'Activa'
AND r.estado IN ('Pendiente', 'Confirmada')
AND r.fecha_inicio > NOW();

-- 16. Mostrar usuarios con membresía Corporativa y su empresa
SELECT u.usuario_id, u.nombre, u.apellidos, e.nombre AS empresa
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
JOIN membresias_tipo mt ON um.tipo_id = mt.tipo_id
JOIN empresas e ON u.empresa_id = e.empresa_id
WHERE mt.nombre LIKE '%Corporativa%' AND um.estado = 'Activa';

-- 17. Identificar usuarios con membresía diaria que la han renovado más de 10 veces
SELECT u.usuario_id, u.nombre, u.apellidos, um.renovaciones
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
JOIN membresias_tipo mt ON um.tipo_id = mt.tipo_id
WHERE mt.nombre LIKE '%Diaria%' AND um.renovaciones > 10;

-- 18. Mostrar usuarios cuya membresía vence en los próximos 7 días
SELECT u.usuario_id, u.nombre, u.apellidos, um.fecha_fin
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Activa'
AND um.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);

-- 19. Listar usuarios que se registraron en el último mes
SELECT usuario_id, nombre, apellidos, fecha_registro
FROM usuarios
WHERE fecha_registro >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 20. Mostrar usuarios que nunca han asistido al coworking (0 accesos)
SELECT u.*
FROM usuarios u
LEFT JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.acceso_id IS NULL;

-- 21. Listar todos los espacios disponibles con su capacidad
SELECT espacio_id, nombre, tipo, capacidad, descripcion
FROM espacios
WHERE activo = TRUE;

-- 22. Listar reservas activas en el día actual
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE DATE(r.fecha_inicio) = CURDATE()
AND r.estado IN ('Pendiente', 'Confirmada');

-- 23. Mostrar reservas canceladas en el último mes
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE r.estado = 'Cancelada'
AND r.fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 24. Listar reservas de salas de reuniones en horario pico (9 am – 11 am)
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE e.tipo = 'SalaReuniones'
AND TIME(r.fecha_inicio) BETWEEN '09:00:00' AND '11:00:00'
AND r.estado IN ('Pendiente', 'Confirmada');

-- 25. Contar cuántas reservas se hacen por cada tipo de espacio
SELECT e.tipo, COUNT(r.reserva_id) AS cantidad_reservas
FROM espacios e
LEFT JOIN reservas r ON e.espacio_id = r.espacio_id
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.tipo;

-- 26. Mostrar el espacio más reservado del último mes
SELECT e.espacio_id, e.nombre, COUNT(r.reserva_id) AS total_reservas
FROM espacios e
JOIN reservas r ON e.espacio_id = r.espacio_id
WHERE r.fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.espacio_id, e.nombre
ORDER BY total_reservas DESC
LIMIT 1;

-- 27. Listar usuarios que más han reservado salas privadas
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(r.reserva_id) AS reservas_salas_privadas
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE e.tipo = 'Oficina'
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY u.usuario_id
ORDER BY reservas_salas_privadas DESC;

-- 28. Mostrar reservas que exceden la capacidad máxima del espacio
SELECT r.*, e.capacidad, r.asistentes
FROM reservas r
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE r.asistentes > e.capacidad;

-- 29. Listar espacios que no se han reservado en la última semana
SELECT e.*
FROM espacios e
LEFT JOIN reservas r ON e.espacio_id = r.espacio_id
AND r.fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE r.reserva_id IS NULL;

-- 30. Calcular la tasa de ocupación promedio de cada espacio
SELECT e.espacio_id, e.nombre, 
       AVG(CASE WHEN r.reserva_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS tasa_ocupacion
FROM espacios e
LEFT JOIN reservas r ON e.espacio_id = r.espacio_id
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.espacio_id, e.nombre;

-- 31. Mostrar reservas de más de 8 horas
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE r.duracion_horas > 8;

-- 32. Identificar usuarios con más de 20 reservas en total
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(r.reserva_id) AS total_reservas
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
GROUP BY u.usuario_id
HAVING COUNT(r.reserva_id) > 20;

-- 33. Mostrar reservas realizadas por empresas con más de 10 empleados
SELECT r.*, e.nombre AS empresa, COUNT(u.usuario_id) AS empleados
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN empresas e ON u.empresa_id = e.empresa_id
GROUP BY r.reserva_id, e.nombre
HAVING COUNT(u.usuario_id) > 10;

-- 34. Listar reservas que se solapan en horario
SELECT r1.reserva_id AS reserva1, r2.reserva_id AS reserva2, 
       r1.espacio_id, r1.fecha_inicio, r1.fecha_fin
FROM reservas r1
JOIN reservas r2 ON r1.espacio_id = r2.espacio_id
AND r1.reserva_id < r2.reserva_id
AND r1.fecha_inicio < r2.fecha_fin
AND r1.fecha_fin > r2.fecha_inicio
WHERE r1.estado IN ('Pendiente', 'Confirmada')
AND r2.estado IN ('Pendiente', 'Confirmada');

-- 35. Listar reservas de fin de semana
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE DAYOFWEEK(r.fecha_inicio) IN (1, 7)
AND r.estado IN ('Pendiente', 'Confirmada');

-- 36. Mostrar el porcentaje de ocupación por cada tipo de espacio
SELECT e.tipo, 
       COUNT(r.reserva_id) * 100.0 / (SELECT COUNT(*) FROM reservas) AS porcentaje_ocupacion
FROM espacios e
LEFT JOIN reservas r ON e.espacio_id = r.espacio_id
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.tipo;

-- 37. Mostrar la duración promedio de reservas por tipo de espacio
SELECT e.tipo, AVG(r.duracion_horas) AS duracion_promedio
FROM espacios e
JOIN reservas r ON e.espacio_id = r.espacio_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.tipo;

-- 38. Mostrar reservas con servicios adicionales incluidos
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio, GROUP_CONCAT(s.nombre) AS servicios
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
JOIN reserva_servicios rs ON r.reserva_id = rs.reserva_id
JOIN servicios s ON rs.servicio_id = s.servicio_id
GROUP BY r.reserva_id;

-- 39. Listar usuarios que reservaron sala de eventos en los últimos 6 meses
SELECT DISTINCT u.*
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
WHERE e.tipo = 'SalaEventos'
AND r.fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
AND r.estado IN ('Pendiente', 'Confirmada');

- 40. Identificar reservas realizadas y nunca asistidas
SELECT r.*, u.nombre, u.apellidos, e.nombre AS espacio
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
JOIN espacios e ON r.espacio_id = e.espacio_id
LEFT JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
AND ra.tipo_acceso = 'Entrada'
AND ra.fecha_hora_acceso BETWEEN r.fecha_inicio AND r.fecha_fin
WHERE r.estado = 'Confirmada'
AND ra.acceso_id IS NULL;



-- 41. Listar todos los pagos realizados con método tarjeta
SELECT p.*, u.nombre, u.apellidos
FROM pagos p
JOIN usuarios u ON p.usuario_id = u.usuario_id
WHERE p.metodo = 'Tarjeta';

-- 42. Listar pagos pendientes de usuarios
SELECT p.*, u.nombre, u.apellidos, f.monto_total, f.referencia
FROM pagos p
JOIN usuarios u ON p.usuario_id = u.usuario_id
JOIN facturas f ON p.factura_id = f.factura_id
WHERE p.estado = 'Pendiente';

-- 43. Mostrar pagos cancelados en los últimos 3 meses
SELECT p.*, u.nombre, u.apellidos, f.monto_total, f.referencia
FROM pagos p
JOIN usuarios u ON p.usuario_id = u.usuario_id
JOIN facturas f ON p.factura_id = f.factura_id
WHERE p.estado = 'Fallido'
AND p.fecha_pago >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

-- 44. Listar facturas generadas por membresías
SELECT f.*, u.nombre, u.apellidos
FROM facturas f
JOIN usuarios u ON f.usuario_id = u.usuario_id
WHERE f.tipo = 'Membresia';

-- 45. Listar facturas generadas por reservas
SELECT f.*, u.nombre, u.apellidos, r.reserva_id
FROM facturas f
JOIN usuarios u ON f.usuario_id = u.usuario_id
JOIN reservas r ON f.referencia = r.reserva_id
WHERE f.tipo = 'Reserva';

-- 46. Mostrar el total de ingresos por membresías en el último mes
SELECT SUM(f.monto_total) AS ingresos_membresias
FROM facturas f
WHERE f.tipo = 'Membresia'
AND f.emitida_en >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
AND f.estado = 'Pagada';

-- 47. Mostrar el total de ingresos por reservas en el último mes
SELECT SUM(f.monto_total) AS ingresos_reservas
FROM facturas f
WHERE f.tipo = 'Reserva'
AND f.emitida_en >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
AND f.estado = 'Pagada';

-- 48. Mostrar el total de ingresos por servicios adicionales
SELECT SUM(f.monto_total) AS ingresos_servicios
FROM facturas f
WHERE f.tipo = 'Servicio'
AND f.estado = 'Pagada';

-- 49. Identificar usuarios que nunca han pagado con PayPal
SELECT u.*
FROM usuarios u
WHERE u.usuario_id NOT IN (
    SELECT DISTINCT p.usuario_id
    FROM pagos p
    WHERE p.metodo = 'PayPal'
);

-- 50. Calcular el gasto promedio por usuario
SELECT u.usuario_id, u.nombre, u.apellidos, AVG(f.monto_total) AS gasto_promedio
FROM usuarios u
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY u.usuario_id;

-- 51. Mostrar el top 5 de usuarios que más han pagado en total
SELECT u.usuario_id, u.nombre, u.apellidos, SUM(f.monto_total) AS total_pagado
FROM usuarios u
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY u.usuario_id
ORDER BY total_pagado DESC
LIMIT 5;

-- 52. Mostrar facturas con monto mayor a $1000
SELECT f.*, u.nombre, u.apellidos
FROM facturas f
JOIN usuarios u ON f.usuario_id = u.usuario_id
WHERE f.monto_total > 1000;

-- 53. Listar pagos realizados después de la fecha de vencimiento
SELECT p.*, u.nombre, u.apellidos, f.fecha_vencimiento
FROM pagos p
JOIN usuarios u ON p.usuario_id = u.usuario_id
JOIN facturas f ON p.factura_id = f.factura_id
WHERE p.fecha_pago > f.fecha_vencimiento;

-- 54. Calcular el total recaudado en el año actual
SELECT SUM(f.monto_total) AS total_recaudado
FROM facturas f
WHERE YEAR(f.emitida_en) = YEAR(CURDATE())
AND f.estado = 'Pagada';

-- 55. Mostrar facturas anuladas y su motivo (CORREGIDA)
SELECT f.*, a.detalles AS motivo_anulacion
FROM facturas f
JOIN auditoria a ON f.factura_id = a.entidad_id
WHERE f.estado = 'Cancelada'
AND a.entidad = 'facturas'
AND a.accion LIKE '%ANULACION%';

-- 56. Mostrar usuarios con facturas pendientes mayores a $200
SELECT u.usuario_id, u.nombre, u.apellidos, SUM(f.saldo_pendiente) AS total_pendiente
FROM usuarios u
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pendiente'
GROUP BY u.usuario_id
HAVING SUM(f.saldo_pendiente) > 200;

-- 57. Mostrar usuarios que han pagado más de una vez el mismo servicio (CORREGIDA)
SELECT u.usuario_id, u.nombre, u.apellidos, s.nombre AS servicio, COUNT(p.pago_id) AS veces_pagado
FROM usuarios u
JOIN pagos p ON u.usuario_id = p.usuario_id
JOIN facturas f ON p.factura_id = f.factura_id
JOIN servicios s ON f.referencia = s.servicio_id
WHERE f.tipo = 'Servicio'
GROUP BY u.usuario_id, s.servicio_id
HAVING COUNT(p.pago_id) > 1;

-- 58. Listar ingresos por cada método de pago
SELECT p.metodo, SUM(p.monto) AS total_ingresos
FROM pagos p
WHERE p.estado = 'Pagado'
GROUP BY p.metodo;

-- 59. Mostrar facturación acumulada por empresa
SELECT e.empresa_id, e.nombre, SUM(f.monto_total) AS facturacion_total
FROM empresas e
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY e.empresa_id;

-- 60. Mostrar ingresos netos por mes del último año
SELECT YEAR(f.emitida_en) AS año, MONTH(f.emitida_en) AS mes, SUM(f.monto_total) AS ingresos
FROM facturas f
WHERE f.emitida_en >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
AND f.estado = 'Pagada'
GROUP BY YEAR(f.emitida_en), MONTH(f.emitida_en)
ORDER BY año, mes;

-- 61. Listar todos los accesos registrados hoy
SELECT ra.*, u.nombre, u.apellidos
FROM registros_acceso ra
JOIN usuarios u ON ra.usuario_id = u.usuario_id
WHERE DATE(ra.fecha_hora_acceso) = CURDATE();

-- 62. Mostrar usuarios con más de 20 asistencias en el mes
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(ra.acceso_id) AS asistencias
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada'
AND ra.estado = 'Aceptado'
AND MONTH(ra.fecha_hora_acceso) = MONTH(CURDATE())
AND YEAR(ra.fecha_hora_acceso) = YEAR(CURDATE())
GROUP BY u.usuario_id
HAVING COUNT(ra.acceso_id) > 20;

-- 63. Mostrar usuarios que no asistieron en la última semana
SELECT u.*
FROM usuarios u
WHERE u.usuario_id NOT IN (
    SELECT DISTINCT ra.usuario_id
    FROM registros_acceso ra
    WHERE ra.tipo_acceso = 'Entrada'
    AND ra.estado = 'Aceptado'
    AND ra.fecha_hora_acceso >= DATE_SUB(CURDATE(), INTERVAL 1 WEEK)
);

-- 64. Calcular la asistencia promedio por día de la semana
SELECT DAYNAME(fecha_hora_acceso) AS dia_semana, 
       COUNT(*) / COUNT(DISTINCT DATE(fecha_hora_acceso)) AS promedio_asistencias
FROM registros_acceso
WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
GROUP BY DAYOFWEEK(fecha_hora_acceso), DAYNAME(fecha_hora_acceso)
ORDER BY DAYOFWEEK(fecha_hora_acceso);

-- 65. Mostrar los 10 usuarios más constantes (más asistencias)
SELECT u.usuario_id, u.nombre, u.apellidos, COUNT(ra.acceso_id) AS total_asistencias
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY u.usuario_id
ORDER BY total_asistencias DESC
LIMIT 10;

-- 66. Mostrar accesos fuera del horario permitido (CORREGIDA)
SELECT ra.*, u.nombre, u.apellidos
FROM registros_acceso ra
JOIN usuarios u ON ra.usuario_id = u.usuario_id
WHERE (TIME(ra.fecha_hora_acceso) < '08:00:00' OR TIME(ra.fecha_hora_acceso) > '20:00:00')
AND ra.estado = 'Aceptado';

-- 67. Mostrar usuarios que accedieron sin membresía activa (rechazados)
SELECT ra.*, u.nombre, u.apellidos, ra.motivo_rechazo
FROM registros_acceso ra
JOIN usuarios u ON ra.usuario_id = u.usuario_id
WHERE ra.estado = 'Rechazado'
AND ra.motivo_rechazo LIKE '%membresía%';

-- 68. Listar usuarios que solo acceden a los fines de semana
SELECT u.usuario_id, u.nombre, u.apellidos
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
AND DAYOFWEEK(ra.fecha_hora_acceso) IN (1, 7)
AND u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id
    FROM registros_acceso
    WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
    AND DAYOFWEEK(fecha_hora_acceso) BETWEEN 2 AND 6
);

-- 69. Mostrar usuarios que accedieron más de 2 veces en el mismo día
SELECT u.usuario_id, u.nombre, u.apellidos, DATE(ra.fecha_hora_acceso) AS fecha, 
       COUNT(ra.acceso_id) AS accesos
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY u.usuario_id, DATE(ra.fecha_hora_acceso)
HAVING COUNT(ra.acceso_id) > 2;

-- 70. Mostrar el total de accesos diarios en el último mes
SELECT DATE(fecha_hora_acceso) AS fecha, COUNT(*) AS total_accesos
FROM registros_acceso
WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
AND fecha_hora_acceso >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY DATE(fecha_hora_acceso)
ORDER BY fecha;

-- 71. Mostrar usuarios que han accedido pero no tienen reservas
SELECT DISTINCT u.*
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
AND u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id
    FROM reservas
);

-- 72. Mostrar los días con más concurrencia en el coworking
SELECT DATE(fecha_hora_acceso) AS fecha, COUNT(*) AS total_personas
FROM registros_acceso
WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
GROUP BY DATE(fecha_hora_acceso)
ORDER BY total_personas DESC
LIMIT 10;

-- 73. Mostrar usuarios que entraron pero no registraron salida
SELECT u.usuario_id, u.nombre, u.apellidos, MAX(ra.fecha_hora_acceso) AS ultima_entrada
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
AND u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id
    FROM registros_acceso
    WHERE tipo_acceso = 'Salida' AND estado = 'Aceptado'
    AND DATE(fecha_hora_acceso) = DATE(ra.fecha_hora_acceso)
)
GROUP BY u.usuario_id;

-- 74. Mostrar accesos de usuarios con membresía vencida
SELECT ra.*, u.nombre, u.apellidos, um.fecha_fin
FROM registros_acceso ra
JOIN usuarios u ON ra.usuario_id = u.usuario_id
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Vencida'
AND ra.estado = 'Aceptado';

-- 75. Mostrar accesos de usuarios corporativos por empresa
SELECT e.nombre AS empresa, COUNT(ra.acceso_id) AS accesos
FROM empresas e
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY e.empresa_id;

-- 76. Mostrar clientes que nunca han usado el coworking a pesar de pagar membresía
SELECT u.*
FROM usuarios u
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Activa'
AND u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id
    FROM registros_acceso
    WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
);

-- 77. Mostrar accesos rechazados por intentos con QR inválido
SELECT ra.*, u.nombre, u.apellidos
FROM registros_acceso ra
JOIN usuarios u ON ra.usuario_id = u.usuario_id
WHERE ra.estado = 'Rechazado'
AND ra.motivo_rechazo LIKE '%QR%';

-- 78. Mostrar accesos promedio por usuario
SELECT u.usuario_id, u.nombre, u.apellidos, 
       COUNT(ra.acceso_id) / COUNT(DISTINCT DATE(ra.fecha_hora_acceso)) AS promedio_accesos_diarios
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY u.usuario_id;

-- 79. Identificar usuarios que asisten más en la mañana
SELECT u.usuario_id, u.nombre, u.apellidos, 
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '06:00:00' AND '12:00:00' THEN 1 END) AS accesos_manana,
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '12:00:01' AND '18:00:00' THEN 1 END) AS accesos_tarde,
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '18:00:01' AND '23:59:59' THEN 1 END) AS accesos_noche
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY u.usuario_id
HAVING accesos_manana > accesos_tarde AND accesos_manana > accesos_noche;

-- 80. Identificar usuarios que asisten más en la noche
SELECT u.usuario_id, u.nombre, u.apellidos, 
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '06:00:00' AND '12:00:00' THEN 1 END) AS accesos_manana,
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '12:00:01' AND '18:00:00' THEN 1 END) AS accesos_tarde,
       COUNT(CASE WHEN TIME(ra.fecha_hora_acceso) BETWEEN '18:00:01' AND '23:59:59' THEN 1 END) AS accesos_noche
FROM usuarios u
JOIN registros_acceso ra ON u.usuario_id = ra.usuario_id
WHERE ra.tipo_acceso = 'Entrada' AND ra.estado = 'Aceptado'
GROUP BY u.usuario_id
HAVING accesos_noche > accesos_manana AND accesos_noche > accesos_tarde;

-- 81. Mostrar los usuarios con el mayor gasto acumulado
SELECT u.usuario_id, u.nombre, u.apellidos, SUM(f.monto_total) AS gasto_total
FROM usuarios u
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY u.usuario_id
ORDER BY gasto_total DESC;

-- 82. Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales
SELECT e.espacio_id, e.nombre, 
       COUNT(r.reserva_id) AS reservas_confirmadas,
       COUNT(ra.acceso_id) AS asistencias_reales,
       (COUNT(ra.acceso_id) * 100.0 / COUNT(r.reserva_id)) AS tasa_asistencia
FROM espacios e
JOIN reservas r ON e.espacio_id = r.espacio_id
LEFT JOIN registros_acceso ra ON r.usuario_id = ra.usuario_id
AND ra.fecha_hora_acceso BETWEEN r.fecha_inicio AND r.fecha_fin
AND ra.estado = 'Aceptado'
WHERE r.estado = 'Confirmada'
GROUP BY e.espacio_id
ORDER BY reservas_confirmadas DESC;

-- 83. Calcular el promedio de ingresos por usuario usando subconsultas
SELECT u.usuario_id, u.nombre, u.apellidos,
       (SELECT SUM(monto_total) FROM facturas f 
        WHERE f.usuario_id = u.usuario_id AND f.estado = 'Pagada') AS total_gastado,
       (SELECT AVG(monto_total) FROM facturas f 
        WHERE f.usuario_id = u.usuario_id AND f.estado = 'Pagada') AS promedio_gasto
FROM usuarios u;

-- 84. Listar usuarios que tienen reservas activas y facturas pendientes
SELECT u.usuario_id, u.nombre, u.apellidos,
       COUNT(r.reserva_id) AS reservas_activas,
       SUM(f.saldo_pendiente) AS total_pendiente
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
AND r.fecha_inicio > NOW()
AND f.estado = 'Pendiente'
GROUP BY u.usuario_id
HAVING total_pendiente > 0;

-- 85. Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales
SELECT e.empresa_id, e.nombre, SUM(f.monto_total) AS ingresos_empresa,
       (SUM(f.monto_total) * 100.0 / (SELECT SUM(monto_total) FROM facturas WHERE estado = 'Pagada')) AS porcentaje_total
FROM empresas e
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY e.empresa_id
HAVING porcentaje_total > 20
ORDER BY porcentaje_total DESC;

-- 86. Mostrar el top 5 de usuarios que más usan servicios adicionales
SELECT u.usuario_id, u.nombre, u.apellidos, 
       COUNT(rs.reserva_id) AS servicios_utilizados
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN reserva_servicios rs ON r.reserva_id = rs.reserva_id
GROUP BY u.usuario_id
ORDER BY servicios_utilizados DESC
LIMIT 5;

-- 87. Mostrar reservas que generaron facturas mayores al promedio
SELECT r.*, f.monto_total
FROM reservas r
JOIN facturas f ON r.reserva_id = f.referencia AND f.tipo = 'Reserva'
WHERE f.monto_total > (SELECT AVG(monto_total) FROM facturas WHERE tipo = 'Reserva' AND estado = 'Pagada');

-- 88. Calcular el porcentaje de ocupación global del coworking por meses
SELECT YEAR(r.fecha_inicio) AS año, MONTH(r.fecha_inicio) AS mes,
       COUNT(r.reserva_id) AS total_reservas,
       (COUNT(r.reserva_id) * 100.0 / (SELECT COUNT(*) FROM reservas)) AS porcentaje_ocupacion
FROM reservas r
WHERE r.estado IN ('Pendiente', 'Confirmada')
GROUP BY YEAR(r.fecha_inicio), MONTH(r.fecha_inicio)
ORDER BY año, mes;

-- 89. Mostrar usuarios que tienen más horas de reserva que el promedio del sistema
SELECT u.usuario_id, u.nombre, u.apellidos, 
       SUM(r.duracion_horas) AS total_horas_reservadas
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
GROUP BY u.usuario_id
HAVING SUM(r.duracion_horas) > (SELECT AVG(duracion_horas) FROM reservas WHERE estado IN ('Pendiente', 'Confirmada'));

-- 90. Mostrar el top 3 de salas más usadas en el último trimestre
SELECT e.espacio_id, e.nombre, COUNT(r.reserva_id) AS total_reservas
FROM espacios e
JOIN reservas r ON e.espacio_id = r.espacio_id
WHERE r.fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
AND r.estado IN ('Pendiente', 'Confirmada')
GROUP BY e.espacio_id
ORDER BY total_reservas DESC
LIMIT 3;

-- 91. Calcular ingresos promedio por tipo de membresía
SELECT mt.nombre AS tipo_membresia, AVG(f.monto_total) AS ingreso_promedio
FROM membresias_tipo mt
JOIN usuario_membresias um ON mt.tipo_id = um.tipo_id
JOIN facturas f ON um.usuario_id = f.usuario_id AND f.tipo = 'Membresia'
WHERE f.estado = 'Pagada'
GROUP BY mt.tipo_id;

-- 92. Mostrar usuarios que pagan solo con un método de pago
SELECT u.usuario_id, u.nombre, u.apellidos, 
       COUNT(DISTINCT p.metodo) AS metodos_pago
FROM usuarios u
JOIN pagos p ON u.usuario_id = p.usuario_id
WHERE p.estado = 'Pagado'
GROUP BY u.usuario_id
HAVING COUNT(DISTINCT p.metodo) = 1;

-- 93. Mostrar reservas canceladas por usuarios que nunca asistieron
SELECT r.*, u.nombre, u.apellidos
FROM reservas r
JOIN usuarios u ON r.usuario_id = u.usuario_id
WHERE r.estado = 'Cancelada'
AND u.usuario_id NOT IN (
    SELECT DISTINCT usuario_id
    FROM registros_acceso
    WHERE tipo_acceso = 'Entrada' AND estado = 'Aceptado'
);

-- 94. Mostrar facturas con pagos parciales y calcular saldo pendiente
SELECT f.factura_id, f.usuario_id, f.monto_total,
       COALESCE(SUM(p.monto), 0) AS total_pagado,
       (f.monto_total - COALESCE(SUM(p.monto), 0)) AS saldo_pendiente
FROM facturas f
LEFT JOIN pagos p ON f.factura_id = p.factura_id AND p.estado = 'Pagado'
WHERE f.estado = 'Pendiente'
GROUP BY f.factura_id
HAVING saldo_pendiente > 0;

-- 95. Calcular la facturación total de cada empresa y ordenarla de mayor a menor
SELECT e.empresa_id, e.nombre, SUM(f.monto_total) AS facturacion_total
FROM empresas e
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN facturas f ON u.usuario_id = f.usuario_id
WHERE f.estado = 'Pagada'
GROUP BY e.empresa_id
ORDER BY facturacion_total DESC;

-- 96. Identificar usuarios que superan en reservas al promedio de su empresa
SELECT u.usuario_id, u.nombre, u.apellidos, e.nombre AS empresa,
       COUNT(r.reserva_id) AS total_reservas,
       (SELECT AVG(COUNT(r2.reserva_id)) 
        FROM usuarios u2 
        JOIN reservas r2 ON u2.usuario_id = r2.usuario_id 
        WHERE u2.empresa_id = u.empresa_id 
        GROUP BY u2.usuario_id) AS promedio_empresa
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN empresas e ON u.empresa_id = e.empresa_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
GROUP BY u.usuario_id
HAVING total_reservas > promedio_empresa;

-- 97. Mostrar las 3 empresas con más empleados activos en el coworking
SELECT e.empresa_id, e.nombre, COUNT(u.usuario_id) AS empleados_activos
FROM empresas e
JOIN usuarios u ON e.empresa_id = u.empresa_id
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE um.estado = 'Activa'
GROUP BY e.empresa_id
ORDER BY empleados_activos DESC
LIMIT 3;

-- 98. Calcula el porcentaje de usuarios activos frente al total de registrados
SELECT 
    (SELECT COUNT(*) FROM usuario_membresias WHERE estado = 'Activa') AS usuarios_activos,
    (SELECT COUNT(*) FROM usuarios) AS usuarios_totales,
    ((SELECT COUNT(*) FROM usuario_membresias WHERE estado = 'Activa') * 100.0 / (SELECT COUNT(*) FROM usuarios)) AS porcentaje_activos;

-- 99. Mostrar ingresos mensuales acumulados
SELECT 
    YEAR(emitida_en) AS año,
    MONTH(emitida_en) AS mes,
    SUM(monto_total) AS ingresos_mensuales,
    @acumulado := @acumulado + SUM(monto_total) AS ingresos_acumulados
FROM facturas, (SELECT @acumulado := 0) r
WHERE estado = 'Pagada'
GROUP BY YEAR(emitida_en), MONTH(emitida_en)
ORDER BY año, mes;

-- 100. Mostrar usuarios con más de 10 reservas, más de $500 en facturación y membresía activa
SELECT u.usuario_id, u.nombre, u.apellidos,
       COUNT(r.reserva_id) AS total_reservas,
       SUM(f.monto_total) AS total_facturado,
       um.estado AS estado_membresia
FROM usuarios u
JOIN reservas r ON u.usuario_id = r.usuario_id
JOIN facturas f ON u.usuario_id = f.usuario_id
JOIN usuario_membresias um ON u.usuario_id = um.usuario_id
WHERE r.estado IN ('Pendiente', 'Confirmada')
AND f.estado = 'Pagada'
AND um.estado = 'Activa'
GROUP BY u.usuario_id
HAVING total_reservas > 10 AND total_facturado > 500;
