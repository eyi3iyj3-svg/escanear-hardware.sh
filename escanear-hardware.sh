#!/bin/bash

# ====================================================================
# Escáner de Hardware y Sistema para Linux
# ====================================================================

TABLE_DATA=""

add_row() {
    TABLE_DATA+="$1|$2|$3|$4\n"
}

# Encabezado de la tabla
add_row "Componente" "Nombre / Modelo" "Descripcion" "ID / Version / Fecha"
add_row "----------" "---------------" "-----------" "--------------------"

# 1. Distribución de Linux
if [ -f /etc/os-release ]; then
    DISTRO=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
elif [ -f /etc/redhat-release ]; then
    DISTRO=$(cat /etc/redhat-release)
elif [ -f /etc/issue ]; then
    DISTRO=$(head -n1 /etc/issue | cut -d'\' -f1)
else
    DISTRO="Linux Generico"
fi
add_row "Distribucion" "${DISTRO:-Linux}" "Sistema Operativo Actual" "-"

# 2. Kernel de Linux
add_row "Kernel Linux" "$(uname -r)" "Version del Nucleo" "$(uname -m)"

# 3. Equipo / Laptop
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
SYS_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
add_row "Equipo" "${SYS_VENDOR:-Generico} ${SYS_MODEL:-}" "Modelo de Computadora / Laptop" "-"

# 4. Placa Madre
BOARD_VENDOR=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
BOARD_NAME=$(cat /sys/class/dmi/id/board_name 2>/dev/null)
add_row "Placa Madre" "${BOARD_VENDOR:-Generica} ${BOARD_NAME:-}" "Tarjeta Madre (Chipset)" "-"

# 5. BIOS / UEFI
BIOS_VER=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
BIOS_DATE=$(cat /sys/class/dmi/id/bios_date 2>/dev/null)
add_row "BIOS / UEFI" "${BIOS_VER:-Desconocido}" "Firmware principal del sistema" "${BIOS_DATE:-N/A}"

# 6. Procesador (CPU)
CPU_NAME=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^[ \t]*//')
if [ -z "$CPU_NAME" ]; then
    CPU_NAME=$(grep -m1 'Hardware' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^[ \t]*//')
fi
CPU_THREADS=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
add_row "Procesador" "${CPU_NAME:-Procesador Generico}" "${CPU_THREADS:-1} Hilos logicos" "-"

# 7. Memoria RAM
MEM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
if [ -n "$MEM_KB" ]; then
    RAM_TOTAL=$(awk "BEGIN {printf \"%.2f GB\", $MEM_KB/1048576}")
else
    RAM_TOTAL="N/A"
fi
add_row "Memoria RAM" "$RAM_TOTAL Total" "Memoria de Trabajo" "-"

# 8. Almacenamiento (Discos)
for disk in /sys/block/*; do
    dev=$(basename "$disk")
    if [[ "$dev" =~ ^(loop|ram|zram|sr) ]]; then continue; fi
    if [ -f "$disk/size" ]; then
        sectors=$(cat "$disk/size" 2>/dev/null)
        if [ "$sectors" -gt 0 ] 2>/dev/null; then
            size_gb=$(awk "BEGIN {printf \"%.2f GB\", $sectors*512/1073741824}")
            model="Disco ($dev)"
            if [ -f "$disk/device/model" ]; then
                model=$(cat "$disk/device/model" 2>/dev/null | sed 's/^[ \t]*//')
            fi
            add_row "Disco Duro/SSD" "$model" "Unidad de Almacenamiento" "$size_gb (/dev/$dev)"
        fi
    fi
done

# 9, 10, 11, 12. Componentes PCI (GPU, Wi-Fi, Audio, USB)
LSPCI_BIN=""
for path in lspci /usr/bin/lspci /sbin/lspci /usr/sbin/lspci; do
    if command -v "$path" &>/dev/null || [ -x "$path" ]; then
        LSPCI_BIN="$path"
        break
    fi
done

if [ -n "$LSPCI_BIN" ]; then
    LSPCI_OUT=$("$LSPCI_BIN" -nn 2>/dev/null)
    
    if [ -n "$LSPCI_OUT" ]; then
        while IFS= read -r line; do
            pci_id=$(echo "$line" | grep -oE '\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]' | tail -n1)
            dev_name=$(echo "$line" | sed -E 's/^[^:]*:[^:]*:[ ]*//' | sed -E 's/ \[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\].*//')

            if echo "$line" | grep -qE -i "vga|3d|display"; then
                add_row "Grafica (GPU)" "$dev_name" "Controlador de Video" "${pci_id:-N/A}"
            elif echo "$line" | grep -qE -i "network|wireless|ethernet|net"; then
                add_row "Red / Wi-Fi" "$dev_name" "Tarjeta de Red" "${pci_id:-N/A}"
            elif echo "$line" | grep -qE -i "audio|sound"; then
                add_row "Audio" "$dev_name" "Dispositivo de Sonido" "${pci_id:-N/A}"
            elif echo "$line" | grep -qE -i "usb"; then
                add_row "Puerto USB" "$dev_name" "Controlador USB" "${pci_id:-N/A}"
            fi
        done <<< "$LSPCI_OUT"
    fi
else
    # Mapeo directo si lspci no existe
    for dev_dir in /sys/bus/pci/devices/*; do
        [ -d "$dev_dir" ] || continue
        if [ -f "$dev_dir/vendor" ] && [ -f "$dev_dir/device" ]; then
            v_id=$(cat "$dev_dir/vendor" 2>/dev/null | sed 's/0x//')
            d_id=$(cat "$dev_dir/device" 2>/dev/null | sed 's/0x//')
            class=$(cat "$dev_dir/class" 2>/dev/null)
            pci_str="[$v_id:$d_id]"

            case "$class" in
                0x03*) add_row "Grafica (GPU)" "Dispositivo GPU" "Controlador de Video" "$pci_str" ;;
                0x02*) add_row "Red / Wi-Fi" "Dispositivo Red" "Tarjeta de Red" "$pci_str" ;;
                0x04*) add_row "Audio" "Dispositivo Audio" "Dispositivo de Sonido" "$pci_str" ;;
                0x0c03*) add_row "Puerto USB" "Controlador USB" "Puerto USB" "$pci_str" ;;
            esac
        fi
    done
fi

# 13. Batería
BAT_PATH=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
if [ -n "$BAT_PATH" ]; then
    BAT_CAP=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    BAT_STAT=$(cat "$BAT_PATH/status" 2>/dev/null)
    add_row "Bateria" "Bateria Integrada" "Carga actual: ${BAT_CAP}%" "${BAT_STAT:-N/A}"
fi

# Formateador nativo en AWK
echo -e "$TABLE_DATA" | awk -F'|' '
{
    for (i=1; i<=NF; i++) {
        gsub(/^ +| +$/, "", $i)
        if (length($i) > w[i]) w[i] = length($i)
        grid[NR, i] = $i
    }
    if (NF > max_col) max_col = NF
    max_row = NR
}
END {
    for (r=1; r<=max_row; r++) {
        for (c=1; c<=max_col; c++) {
            printf "%-*s  ", w[c], grid[r, c]
        }
        print ""
    }
}'
