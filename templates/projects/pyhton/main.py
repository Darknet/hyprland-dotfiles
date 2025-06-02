#!/usr/bin/env python3
"""
Plantilla básica de Python
Autor: Tu Nombre
Fecha: $(date +%Y-%m-%d)
"""

import sys
import os
from pathlib import Path


def main():
    """Función principal del programa"""
    print("¡Hola, mundo desde Python!")
    print(f"Python version: {sys.version}")
    print(f"Directorio actual: {Path.cwd()}")


if __name__ == "__main__":
    main()
