-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SG_Hotelera')
BEGIN
    CREATE DATABASE SG_Hotelera;
END
GO

USE SG_Hotelera;
GO

/* ------------------------------
    Catalogos de la base de datos 
   ------------------------------ */
 
-- Tipo de Alojamiento 
CREATE TABLE TipoAlojamiento (
    tipo_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo VARCHAR(100) NOT NULL
);
GO

-- Tipo de Cama
CREATE TABLE TipoCama (
    tipo_cama_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo_cama VARCHAR(100) NOT NULL
);
GO

-- Lista de servicios que brinda la empresa
CREATE TABLE Servicio (
    servicio_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_servicio VARCHAR(100) NOT NULL
);
GO

-- Tipo de Actividad (Tour en bote, Kayak, etc.)
CREATE TABLE TipoActividad (
    tipo_actividad_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo_actividad VARCHAR(100) NOT NULL UNIQUE
);
GO

-- Tipo de Servicio (guía, transporte, equipo, etc.)
CREATE TABLE TipoServicioRecreacion (
    tipo_servicio_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_servicio VARCHAR(100) NOT NULL UNIQUE
);
GO

-- Tipo de Foto (catálogo para clasificar fotos)
CREATE TABLE TipoFoto (
    tipo_foto_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo_foto VARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE Paises (
    pais_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_pais VARCHAR(100) NOT NULL
);
GO

CREATE TABLE Empresa (
    cedula_juridica VARCHAR(50) PRIMARY KEY,
    nombre_empresa VARCHAR(255) NOT NULL,
    tipo_alojamiento INT NOT NULL,
    -- Direccion: Atributo compuesto posee prov, cant, dist, exact
    provincia VARCHAR(100) NOT NULL,
    canton VARCHAR(100) NOT NULL,
    distrito VARCHAR(100) NOT NULL,
    direccion_exacta VARCHAR(255) NOT NULL,
    -- Telefono Atributo Multivalorado (ver tabla TelefonoEmpresa)
    correo_electronico VARCHAR(255) NOT NULL, -- Tiene que tener formato de correo
    url_sitio_web VARCHAR(255),
    redes_sociales VARCHAR(255),
    CONSTRAINT FK_Empresa_TipoAlojamiento
        FOREIGN KEY (tipo_alojamiento)
        REFERENCES TipoAlojamiento(tipo_id),
    -- Validar formato de cédula jurídica: D-DDDD-DDDD (ej: 1-2345-6789)
    CONSTRAINT CHK_Cedula_Juridica_Formato
        CHECK (cedula_juridica LIKE '[0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    -- Validar formato de correo: usuario@dominio.extensión
    CONSTRAINT CHK_Correo_Electronico_Formato
        CHECK (correo_electronico LIKE '%@%.%')
);
GO

-- Atributo multivalorado TelefonoEmpresa
CREATE TABLE TelefonoEmpresa (
    empresa_id VARCHAR(50) NOT NULL,
    numero_telefono VARCHAR(15) NOT NULL,
    codigo_pais VARCHAR(5) NOT NULL,
    PRIMARY KEY (empresa_id, numero_telefono),
    CONSTRAINT FK_Telefono_Empresa 
        FOREIGN KEY (empresa_id) 
        REFERENCES Empresa(cedula_juridica),
    -- Validar formato de teléfono de Costa Rica: 8/7 XXXX XXXX
    CONSTRAINT CHK_Telefono_Formato
        CHECK (numero_telefono LIKE '[2-8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    -- Validar código de país: solo números, máximo 5 dígitos
    CONSTRAINT CHK_Codigo_Pais_Valido
        CHECK (codigo_pais LIKE '[0-9][0-9][0-9]' OR codigo_pais LIKE '[0-9][0-9][0-9][0-9]')
);
GO

-- Tabla intermedia entre Empresa y Servicio (relacion muchos a muchos)
CREATE TABLE EmpresaServicio (
    empresa_id VARCHAR(50) NOT NULL,
    servicio_id INT NOT NULL,
    PRIMARY KEY (empresa_id, servicio_id),
    CONSTRAINT FK_EmpresaServicio_Empresa
        FOREIGN KEY (empresa_id)
        REFERENCES Empresa(cedula_juridica),
    CONSTRAINT FK_EmpresaServicio_Servicio
        FOREIGN KEY (servicio_id)
        REFERENCES Servicio(servicio_id)
);
GO



-- Tipo de Habitacion
CREATE TABLE TipoHabitacion (
    tipo_habitacion_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo_habitacion VARCHAR(100) NOT NULL,
    descripcion_tipo_habitacion VARCHAR(255) NOT NULL,
    tipo_cama_id INT NOT NULL,
    precio_noche DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_TipoHabitacion_TipoCama
        FOREIGN KEY (tipo_cama_id)
        REFERENCES TipoCama(tipo_cama_id)
);
GO

-- Habitacion
CREATE TABLE Habitacion (
    habitacion_id INT IDENTITY(1,1) PRIMARY KEY, -- nO INCREMENTEA
    numero_habitacion INT NOT NULL,
    tipo_habitacion_id INT NOT NULL,
    empresa_id VARCHAR(50) NOT NULL,
    estado_habitacion BIT NOT NULL DEFAULT 1, -- 1: Disponible, 0: No Disponible

    CONSTRAINT FK_Habitacion_TipoHabitacion
        FOREIGN KEY (tipo_habitacion_id)
        REFERENCES TipoHabitacion(tipo_habitacion_id),
    CONSTRAINT FK_Habitacion_Empresa
        FOREIGN KEY (empresa_id)
        REFERENCES Empresa(cedula_juridica),
    CONSTRAINT UQ_Empresa_NumeroHabitacion
        UNIQUE (empresa_id, numero_habitacion)
);
GO

-- Fotos de Habitación
CREATE TABLE FotoHabitacion (
    foto_id INT IDENTITY(1,1) PRIMARY KEY,
    habitacion_id INT NOT NULL,
    tipo_foto_id INT NOT NULL,
    ruta_foto VARCHAR(500) NOT NULL,
    descripcion_foto VARCHAR(255),
    fecha_carga DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_FotoHabitacion_Habitacion
        FOREIGN KEY (habitacion_id)
        REFERENCES Habitacion(habitacion_id),
    CONSTRAINT FK_FotoHabitacion_TipoFoto
        FOREIGN KEY (tipo_foto_id)
        REFERENCES TipoFoto(tipo_foto_id)
);
GO

-- Cliente
CREATE TABLE Cliente (
    -- pk: Cédula en formato D-DDDD-DDDD o VARCHAR para flexibilidad internacional
    cliente_identificacion VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    primer_apellido VARCHAR(100) NOT NULL,
    segundo_apellido VARCHAR(100) NOT NULL,
    pais_residencia INT NOT NULL, -- FK a Paises
    -- Direccion si fuese costarricense
    provincia VARCHAR(100),
    canton VARCHAR(100),
    distrito VARCHAR(100),
    correo_electronico VARCHAR(255) NOT NULL, -- Tiene que tener formato de correo
    CONSTRAINT FK_Cliente_Paises
        FOREIGN KEY (pais_residencia)
        REFERENCES Paises(pais_id),
    -- Validar formato de cédula de cliente (Costa Rica): D-DDDD-DDDD
    CONSTRAINT CHK_Cedula_Cliente_Formato
        CHECK (cliente_identificacion LIKE '[0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    -- Validar formato de correo: usuario@dominio.extensión
    CONSTRAINT CHK_Correo_Cliente_Formato
        CHECK (correo_electronico LIKE '%@%.%')
);
GO

-- Multivalorado TelefonoCliente
CREATE TABLE TelefonoCliente (
    cliente_id VARCHAR(50) NOT NULL,
    numero_telefono VARCHAR(15) NOT NULL,
    codigo_pais VARCHAR(5) NOT NULL,
    PRIMARY KEY (cliente_id, numero_telefono),
    CONSTRAINT FK_Telefono_Cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Cliente(cliente_identificacion),
    -- Validar formato de teléfono de Costa Rica: 8/7 XXXX XXXX
    CONSTRAINT CHK_Telefono_Cliente_Formato
        CHECK (numero_telefono LIKE '[7-8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    -- Validar código de país: solo números, máximo 5 dígitos
    CONSTRAINT CHK_Codigo_Pais_Cliente_Valido
        CHECK (codigo_pais LIKE '[0-9][0-9][0-9]' OR codigo_pais LIKE '[0-9][0-9][0-9][0-9]')
);
GO

-- Reserva
CREATE TABLE Reserva (
    reserva_id INT IDENTITY(1,1) PRIMARY KEY,
    cliente_id VARCHAR(50) NOT NULL,
    habitacion_id INT NOT NULL,
    fecha_check_in DATETIME NOT NULL,
    fecha_check_out DATETIME NOT NULL,
    cantidad_personas INT NOT NULL,
    vehiculo BIT NOT NULL, -- 1: Si, 0: No
    CONSTRAINT FK_Reserva_Cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Cliente(cliente_identificacion),
    CONSTRAINT FK_Reserva_Habitacion
        FOREIGN KEY (habitacion_id)
        REFERENCES Habitacion(habitacion_id)
);
GO

CREATE TABLE Factura (
    factura_id INT IDENTITY(1,1) PRIMARY KEY,
    reserva_id INT NOT NULL,
    noches_estadia INT NOT NULL,
    fecha_emision DATETIME NOT NULL,
    importe_total DECIMAL(10,2) NOT NULL,
    medio_pago BIT NOT NULL, -- 1: Tarjeta, 0: Efectivo
    CONSTRAINT FK_Factura_Reserva
        FOREIGN KEY (reserva_id)
        REFERENCES Reserva(reserva_id)
);
GO

CREATE TABLE EmpresaRecreacion (
    empresa_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_empresa VARCHAR(255) NOT NULL,
    cedula_juridica VARCHAR(50) NOT NULL UNIQUE,
    correo_electronico VARCHAR(255) NOT NULL,
    nombre_contacto VARCHAR(150) NOT NULL,
    -- Dirección (atributo compuesto)
    provincia VARCHAR(100) NOT NULL,
    canton VARCHAR(100) NOT NULL,
    distrito VARCHAR(100) NOT NULL,
    direccion_exacta VARCHAR(255) NOT NULL,
    descripcion_actividad VARCHAR(500),
    precio DECIMAL(10,2) NOT NULL,
    -- Validar formato de cédula jurídica: D-DDDD-DDDD (ej: 1-2345-6789)
    CONSTRAINT CHK_Cedula_Recreacion_Formato
        CHECK (cedula_juridica LIKE '[0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    -- Validar formato de correo: usuario@dominio.extensión
    CONSTRAINT CHK_Correo_Recreacion_Formato
        CHECK (correo_electronico LIKE '%@%.%')
);
GO

-- TELEFONOS (MULTIVALORADO)
CREATE TABLE TelefonoEmpresaRecreacion (
    empresa_id INT NOT NULL,
    codigo_pais VARCHAR(5) NOT NULL,
    numero_telefono VARCHAR(15) NOT NULL,
    PRIMARY KEY (empresa_id, numero_telefono),
    CONSTRAINT FK_Telefono_EmpresaRecreacion
        FOREIGN KEY (empresa_id)
        REFERENCES EmpresaRecreacion(empresa_id),
    -- Validar formato de teléfono de Costa Rica: 8/7 XXXX XXXX
    CONSTRAINT CHK_Telefono_Recreacion_Formato
        CHECK (numero_telefono LIKE '[7-8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    -- Validar código de país: solo números, máximo 5 dígitos
    CONSTRAINT CHK_Codigo_Pais_Recreacion_Valido
        CHECK (codigo_pais LIKE '[0-9][0-9][0-9]' OR codigo_pais LIKE '[0-9][0-9][0-9][0-9]')
);
GO

-- Empresa <-> TipoActividad (Muchos a muchos)
CREATE TABLE EmpresaTipoActividad (
    empresa_id INT NOT NULL,
    tipo_actividad_id INT NOT NULL,
    PRIMARY KEY (empresa_id, tipo_actividad_id),
    CONSTRAINT FK_EmpresaTipoActividad_Empresa
        FOREIGN KEY (empresa_id)
        REFERENCES EmpresaRecreacion(empresa_id),
    CONSTRAINT FK_EmpresaTipoActividad_TipoActividad
        FOREIGN KEY (tipo_actividad_id)
        REFERENCES TipoActividad(tipo_actividad_id)
);
GO

-- Empresa <-> TipoServicio (Muchos a muchos)
CREATE TABLE EmpresaServicioRecreacion (
    empresa_id INT NOT NULL,
    tipo_servicio_id INT NOT NULL,
    PRIMARY KEY (empresa_id, tipo_servicio_id),
    CONSTRAINT FK_EmpresaServicioRecreacion_Empresa
        FOREIGN KEY (empresa_id)
        REFERENCES EmpresaRecreacion(empresa_id),
    CONSTRAINT FK_EmpresaServicioRecreacion_Servicio
        FOREIGN KEY (tipo_servicio_id)
        REFERENCES TipoServicioRecreacion(tipo_servicio_id)
);
GO
