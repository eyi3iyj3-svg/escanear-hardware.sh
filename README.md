# escanear-hardware.sh
# 🖥️ Escáner de Hardware para Linux

Herramienta ultraligera de un solo clic que extrae la tabla completa de componentes (GPU, Wi-Fi, BIOS, Audio, RAM, Kernel y Distribución) con sus identificadores de hardware (`PCI IDs`).

1. Descarga el archivo `escanear-hardware.sh`.
2. Abre la terminal en la carpeta donde lo descargaste y dale permisos de ejecución:
   ```bash
   chmod +x escanear-hardware.sh
   ./escanear-hardware.sh
 # automatico
   ```bash

curl -sSL https://raw.githubusercontent.com/eyi3iyj3-svg/escanear-hardware.sh/main/escanear-hardware.sh | bash
 
 # 🖥️ Escáner de Hardware "Bare Metal" para Computadoras Nuevas (o Viejas)

Esta herramienta te permite extraer **toda** la información técnica de una laptop o computadora (incluyendo BIOS, códigos PCI de GPU, Wi-Fi, Audio y parches del Kernel), **incluso si al intentar instalar Windows o Linux la pantalla se queda negra o da error.**

Está diseñado para que cualquier persona, sin conocimientos de informática, pueda crear una USB de diagnóstico que arranque SÍ O SÍ. Con este reporte en la mano, sabrás exactamente qué versión de Linux instalar o qué parches agregar para que tu computadora funcione perfectamente.

---

## 🛠️ Cómo Crear tu USB de Diagnóstico (Paso a Paso)

Este proceso se realiza en otra computadora que funcione correctamente.
