# 🚀 Optimiza Laptop
> **Suite de Herramientas Nativas, Diagnóstico y Optimización de Rendimiento para Laptops con Windows 10 y Windows 11.**

Una colección de scripts y aplicaciones de escritorio desarrolladas a medida para exprimir el rendimiento de la laptop, eliminar el bloatware, automatizar el mantenimiento y calibrar periféricos (pantalla, sonido y touchpad) sin necesidad de software de terceros invasivo.

---

## 📦 Contenido de la Suite

### 1. 🧹 Mantenimiento Automático Profundo (`Mantenimiento_Auto.ps1`)
Script integral que se puede ejecutar manualmente o programar semanalmente en Windows:
- **Puntos de Restauración Reales:** Crea una instantánea del sistema (`Auto_Mantenimiento_YYYY-MM-DD`) antes de cada optimización.
- **Desglose Detallado por Categorías:** Mide e informa individualmente archivos y MB liberados en temporales de usuario (`%TEMP%`, CrashDumps), temporales de Windows (`SoftwareDistribution`), caché web de navegadores, informes WER y papelera.
- **Cronómetro de Alta Precisión:** Registra con precisión de centésimas de segundo la duración total del análisis y la limpieza.
- **Eliminación Inteligente de Duplicados (SHA-256):** Escanea Descargas y Escritorio agrupando por tamaño y comparando hashes criptográficos SHA-256; conserva siempre el archivo original y purga automáticamente los clones redundantes (`(1)`, `- Copia`).
- **Optimización TRIM para SSDs:** Ejecuta `Optimize-Volume -ReTrim` en la unidad C: para mantener las celdas del disco de estado sólido en máxima velocidad de lectura y escritura.
- **Auditoría Inteligente de Wallpaper en RAM:** Analiza en tiempo real las dimensiones y la huella en memoria de video/RAM del fondo activo; si es seguro y ligero (< 25 MB en disco y < 35 MB de búfer DWM), lo conserva intacto al 100% garantizando el modo imagen sin forzar pantallas negras.
- **Búsqueda Instantánea sin Bing:** Desactiva la telemetría de Bing y las sugerencias remotas en el menú Inicio de Windows 11 (`DisableWebSearch = 1`), haciendo que la búsqueda de aplicaciones locales responda en milisegundos.
- **Calibración Balística de Touchpad:** Mantiene la aceleración del ratón desactivada y el desplazamiento suave a 3 líneas.
- **Reporte Ejecutivo Único:** Genera un único informe limpio en el Escritorio (`Reporte_Mantenimiento.txt`) y guarda los registros técnicos en una bitácora interna (`Historial_Limpiezas.log`).

### 2. 🖥️ Monitor de Hardware en Tiempo Real (`HWStatus`)
Aplicación de escritorio estilo **HWMonitor / NZXT CAM** construida en C# WinForms con tema oscuro moderno:
- **⚡ Procesador (CPU):** Uso en tiempo real (%) con barras térmicas dinámicas, reloj de frecuencia (GHz) y **temperatura del paquete CPU en tiempo real (°C)** leída directamente de los sensores térmicos de Intel Dynamic Tuning (ESIF).
- **💾 Almacenamiento & Temperaturas de Discos:** Monitoreo en vivo de temperatura SMART para **SSD NVMe** y **HDD SATA**, con espacio libre y barras de ocupación.
- **🧠 Memoria RAM:** Gráfico de uso de memoria (GB libres / GB usados) y porcentaje de carga en vivo.
- **🌐 Red Wi-Fi:** Velocidades de descarga (KB/s - MB/s) y subida en tiempo real.
- **🔋 Batería & Energía:** Porcentaje de carga, estado de conexión (CA / Batería) y tasa de consumo/carga en Watts.

### 3. 🎵 Centro de Control de Sonido & Super Booster (`AudioHub`)
Consola de audio compacta para laptops:
- **🎛️ Ecualizador Dolby Audio:** Acceso directo al ecualizador paramétrico oficial calibrado para el chasis de la laptop.
- **🚀 Super Booster (200% - 600%):** 
  - Acceso directo para instalar el amplificador de pestañas **Volume Master** en Microsoft Edge para YouTube, Netflix y streaming.
  - Guía para activar el **Volume Leveler** en Dolby Audio (+200% de potencia acústica sin distorsión).
- **🔊 Presets de Ecualización:** Curvas recomendadas para Música (Bass), Cine, Diálogos/Voz y Gaming.

### 4. ⚡ Esquemas de Energía Duales (1-Clic)
- 🚀 **`Modo_MaximoRendimiento.bat`:** Desbloquea la CPU y gráficos al 100% para trabajo pesado o renderizado con cargador conectado.
- 🍃 **`Modo_SuperEco.bat`:** Activa el perfil Economizador, reduciendo el calentamiento y maximizando la duración de la batería fuera de casa.

### 5. 🖱️ Calibración de Precisión de Touchpad (`Calibrar_Touchpad.ps1`)
- **Modo 1:1 Lineal:** Elimina la aceleración artificial del puntero de Windows (`MouseSpeed = 0`), permitiendo apuntar a botones pequeños y texto con precisión milimétrica.
- **Scroll Suave sin Inercia Loca:** Elimina la inercia fantasma del controlador Elantech (`SC_InertialScroll_Enable = 0`) para que el desplazamiento con dos dedos responda exactamente a la distancia recorrida y frene en seco al levantar los dedos.

### 6. 🗺️ Optimizador de QGIS para Laptops (`Optimizar_QGIS.bat`)
- **Arranque Instantáneo:** Desactiva comprobaciones de versión, descargas de noticias (`feed.qgis.org`) y verificación automática de complementos al abrir, reduciendo el tiempo de carga de minutos a ~5 segundos.
- **Renderizado Multinúcleo:** Activa 3 hilos paralelos de CPU para mapas y rásters sin congelar Windows.
- **Caché Ampliada en RAM:** Eleva la memoria caché de renderizado y mosaicos a **1024 MB** (1 GB).
- **Aceleración GPU DirectX:** Configura prioridad de Alto Rendimiento en Windows para la GPU integrada.
- **Iconos Compactos (16px):** Duplica el área visible del mapa en pantallas de resolución 1366x768.
- **Alivio de Disco HDD:** Desactiva indexación pesada de archivos comprimidos en explorador de capas.

---

## 🛠️ Instalación Rápida

1. Descarga o clona este repositorio en tu laptop (por ejemplo en `C:\Users\TuUsuario\optimiza-laptop`).
2. Haz doble clic en **`Instalar_Todo.bat`**.
3. El script creará automáticamente los 5 accesos directos en tu Escritorio con sus iconos de alta resolución:
   - 🖥️ `Estado del PC (HW Monitor)`
   - 🎵 `Sonido y Ecualizador (AudioHub)`
   - 🚀 `Maximo Rendimiento`
   - 🍃 `Super Eco Bateria`
   - 🧹 `Limpieza y Optimizacion`

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Eres libre de usarlo, modificarlo y compartirlo.
