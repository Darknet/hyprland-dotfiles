# Proyecto Python

## Descripción
Descripción detallada del proyecto.

## Características
- ✅ Configuración moderna de Python
- ✅ Linting con flake8
- ✅ Formateo con black
- ✅ Type checking con mypy
- ✅ Testing con pytest
- ✅ Gestión de dependencias

## Requisitos
- Python 3.8+
- pip

## Instalación

### Desarrollo
```bash
# Clonar el repositorio
git clone <url-del-repo>
cd proyecto

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Instalar dependencias
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### Producción
```bash
pip install -r requirements.txt
```

## Uso
```bash
python main.py
```

## Desarrollo

### Ejecutar tests
```bash
pytest
```

### Formatear código
```bash
black .
```

### Linting
```bash
flake8
```

### Type checking
```bash
mypy .
```

## Estructura del proyecto
```
proyecto/
├── main.py              # Punto de entrada
├── requirements.txt     # Dependencias
├── requirements-dev.txt # Dependencias de desarrollo
├── setup.py            # Configuración del paquete
├── pytest.ini         # Configuración de pytest
├── setup.cfg           # Configuración de herramientas
├── pyproject.toml      # Configuración moderna
├── README.md           # Este archivo
├── tests/              # Tests
└── src/                # Código fuente
```

## Licencia
MIT License
```

```txt:scripts/templates/python-basic/requirements-dev.txt
# Herramientas de desarrollo
pytest>=7.0.0
pytest-cov>=4.0.0
black>=22.0.0
flake8>=4.0.0
mypy>=0.950
isort>=5.10.0
pre-commit>=2.17.0

# Documentación
sphinx>=4.5.0
sphinx-rtd-theme>=1.0.0

# Debugging
ipdb>=0.13.0
```

```gitignore:scripts/templates/python-basic/.gitignore
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# pipenv
Pipfile.lock

# PEP 582
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/
```

### Node.js Basic Template:

```json:scripts/templates/nodejs-basic/package.json
{
  "name": "proyecto-nodejs",
  "version": "1.0.0",
  "description": "Plantilla básica de Node.js con Express",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write src/",
    "build": "echo 'No build step required'",
    "clean": "rm -rf node_modules package-lock.json"
  },
  "keywords": [
    "nodejs",
    "express",
    "api",
    "backend"
  ],
  "author": "Tu Nombre <tu.email@ejemplo.com>",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^6.1.5",
    "morgan": "^1.10.0",
    "dotenv": "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.22",
    "jest": "^29.5.0",
    "supertest": "^6.3.3",
    "eslint": "^8.40.0",
    "prettier": "^2.8.8",
    "@types/jest": "^29.5.1"
  },
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  }
}
```

```javascript:scripts/templates/nodejs-basic/src/index.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
    res.json({
        message: '¡Hola, mundo desde Node.js!',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Something went wrong!',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Internal Server Error'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Route not found',
        path: req.originalUrl
    });
});

// Start server
const server = app.listen(PORT, () => {
    console.log(`🚀 Servidor ejecutándose en puerto ${PORT}`);
    console.log(`📝 Entorno: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 URL: http://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        console.log('Process terminated');
    });
});

module.exports = app;
