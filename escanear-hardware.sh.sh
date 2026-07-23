#!/bin/bash

# ====================================================================
# Escáner de Hardware y Sistema para Linux
# Muestra una tabla estructurada con el Sistema, Kernel e IDs de Hardware
# ====================================================================

# Comprobar si existe la herramienta column para formatear la tabla
if ! command -v column &> /dev/null; then
    echo "Error: Se requiere el comando 'column' para mostrar la tabla correctamente."
    exit 1
fi

# Buffer temporal para acumular las filas de la tabla
TABLE_DATA=""

add_row() {
    TABLE_DATA+="$1 | $2 | $3 | $4\n"
}

# Encabezado de la tabla
add_row "Componente" "Nombre / Modelo" "Descripcion" "ID / Version / Fecha"
add_row "----------" "---------------" "-----------" "--------------------"

# 1. Distribución de Linux
if [ -f /etc/os-release ]; then
    DISTRO=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
    DISTRO="Distribucion Linux Generica"
fi
add_row "Distribucion" "$DISTRO" "Sistema Operativo Actual" "-"

# 2. Versión del Kernel
KERNEL_VER=$(uname -r)
KERNEL_ARCH=$(uname -m)
add_row "Kernel Linux" "$KERNEL_VER" "Version del Nucleo" "$KERNEL_ARCH"

# 3. Equipo / Laptop
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
SYS_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
add_row "Equipo" "${SYS_VENDOR} ${SYS_MODEL}" "Modelo de Computadora / Laptop" "-"

# 4. Placa Madre
BOARD_VENDOR=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
BOARD_NAME=$(cat /sys/class/dmi/id/board_name 2>/dev/null)
add_row "Placa Madre" "${BOARD_VENDOR} ${BOARD_NAME}" "Tarjeta Madre (Chipset)" "-"

# 5. BIOS / UEFI
BIOS_VER=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
BIOS_DATE=$(cat /sys/class/dmi/id/bios_date 2>/dev/null)
add_row "BIOS / UEFI" "${BIOS_VER:-Desconocido}" "Firmware principal del sistema" "${BIOS_DATE:-N/A}"

# 6. Procesador (CPU)
CPU_NAME=$(lscpu 2>/dev/null | grep "Model name:" | sed 's/Model name:[ \t]*//')
CPU_THREADS=$(nproc 2>/dev/null)
add_row "Procesador" "${CPU_NAME:-CPU Generica}" "${CPU_THREADS} Hilos logicos" "-"

# 7. Memoria RAM
RAM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}')
add_row "Memoria RAM" "${RAM_TOTAL:-N/A} Total" "Memoria de Trabajo" "-"

# 8. Almacenamiento (Discos)
if command -v lsblk &> /dev/null; then
    lsblk -dn -o MODEL,SIZE,TRAN 2>/dev/null | while read -r line; do
        [ -n "$line" ] && add_row "Disco Duro/SSD" "$line" "Unidad de Almacenamiento" "-"
    done
fi

# 9. Tarjeta Gráfica (GPU) con PCI ID
if command -v lspci &> /dev/null; then
    lspci -nn | grep -E "VGA|3D|Display" | while read -r line; do
        GPU_NAME=$(echo "$line" | cut -d':' -f3-)
        PCI_ID=$(echo "$line" | grep -o '\[....:....\]' | tail -n1)
        add_row "Grafica (GPU)" "$GPU_NAME" "Controlador de Video" "${PCI_ID:-N/A}"
    done
fi

# 10. Red / Wi-Fi con PCI ID
if command -v lspci &> /dev/null; then
    lspci -nn | grep -i net | while read -r line; do
        NET_NAME=$(echo "$line" | cut -d':' -f3-)
        PCI_ID=$(echo "$line" | grep -o '\[....:....\]' | tail -n1)
        add_row "Red / Wi-Fi" "$NET_NAME" "Tarjeta de Red" "${PCI_ID:-N/A}"
    done
fi

# 11. Audio con PCI ID
if command -v lspci &> /dev/null; then
    lspci -nn | grep -i audio | while read -r line; do
        AUDIO_NAME=$(echo "$line" | cut -d':' -f3-)
        PCI_ID=$(echo "$line" | grep -o '\[....:....\]' | tail -n1)
        add_row "Audio" "$AUDIO_NAME" "Dispositivo de Sonido" "${PCI_ID:-N/A}"
    done
fi

# 12. Controladores USB
if command -v lspci &> /dev/null; then
    lspci -nn | grep -i usb | while read -r line; do
        USB_NAME=$(echo "$line" | cut -d':' -f3-)
        PCI_ID=$(echo "$line" | grep -o '\[....:....\]' | tail -n1)
        add_row "Puerto USB" "$USB_NAME" "Controlador USB" "${PCI_ID:-N/A}"
    done
fi

# 13. Estado de la Batería
BAT_PATH=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
if [ -n "$BAT_PATH" ]; then
    BAT_CAP=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    BAT_STAT=$(cat "$BAT_PATH/status" 2>/dev/null)
    add_row "Bateria" "Bateria Integrada" "Carga actual: ${BAT_CAP}%" "${BAT_STAT:-N/A}"
fi

# Imprimir la tabla alineada
echo -e "$TABLE_DATA" | column -t -s '|'