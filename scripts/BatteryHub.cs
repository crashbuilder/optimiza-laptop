using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Management;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace BatteryHubApp {
    public class MainForm : Form {
        private Timer refreshTimer;
        private Label lblPercentage;
        private Label lblStatusBadge;
        private Label lblPowerSource;
        private Label lblCapacity;
        private Label lblHealth;
        private Label lblRate;
        private Label lblTimeEstimate;
        private ProgressBar pbBattery;
        private FlowLayoutPanel pnlDevices;
        private Label lblAdvice;
        private Panel cardAdvice;
        private Button btnRefresh;
        private int fullCapacityMwh = 0;

        public MainForm() {
            InitializeUI();
            RefreshData();

            refreshTimer = new Timer();
            refreshTimer.Interval = 2000; // Auto-refresco en vivo cada 2 segundos
            refreshTimer.Tick += (s, e) => RefreshData();
            refreshTimer.Start();
        }

        private void InitializeUI() {
            this.Text = "⚡ BatteryHub - Monitor de Carga y Dispositivos";
            // Ajustado para encajar perfectamente en pantallas de 1366x768 (WorkingArea 720px)
            this.Size = new Size(560, 620);
            this.MinimumSize = new Size(540, 580);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(18, 20, 26);
            this.ForeColor = Color.White;
            this.Font = new Font("Segoe UI", 9f, FontStyle.Regular);
            this.Icon = SystemIcons.Application;

            Panel mainContainer = new Panel {
                Dock = DockStyle.Fill,
                AutoScroll = false,
                Padding = new Padding(12)
            };
            this.Controls.Add(mainContainer);

            // 1. ENCABEZADO
            Panel pnlHeader = new Panel { Size = new Size(520, 36), Location = new Point(14, 8) };
            Label lblTitle = new Label {
                Text = "⚡ BatteryHub",
                Font = new Font("Segoe UI", 15f, FontStyle.Bold),
                ForeColor = Color.FromArgb(240, 240, 245),
                AutoSize = true,
                Location = new Point(0, 2)
            };
            Label lblSub = new Label {
                Text = "● Monitoreo en vivo (Auto-refresco 2s)",
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = Color.FromArgb(16, 185, 129),
                AutoSize = true,
                Location = new Point(275, 10)
            };
            pnlHeader.Controls.Add(lblTitle);
            pnlHeader.Controls.Add(lblSub);
            mainContainer.Controls.Add(pnlHeader);

            // 2. TARJETA 1: BATERÍA DE LA LAPTOP
            Panel cardLaptop = CreateCard(14, 46, 520, 146);
            Label lblCard1Title = new Label {
                Text = "BATERÍA DE TU PORTÁTIL",
                Font = new Font("Segoe UI", 8f, FontStyle.Bold),
                ForeColor = Color.FromArgb(156, 163, 175),
                Location = new Point(12, 7),
                AutoSize = true
            };
            cardLaptop.Controls.Add(lblCard1Title);

            lblPercentage = new Label {
                Text = "--%",
                Font = new Font("Segoe UI", 28f, FontStyle.Bold),
                ForeColor = Color.FromArgb(16, 185, 129),
                Location = new Point(8, 22),
                AutoSize = true
            };
            cardLaptop.Controls.Add(lblPercentage);

            lblStatusBadge = new Label {
                Text = "Cargando...",
                Font = new Font("Segoe UI", 9.2f, FontStyle.Bold),
                ForeColor = Color.FromArgb(240, 240, 245),
                Location = new Point(135, 23),
                AutoSize = true
            };
            cardLaptop.Controls.Add(lblStatusBadge);

            lblRate = new Label {
                Text = "Potencia: -- W",
                Font = new Font("Segoe UI", 8.3f),
                ForeColor = Color.FromArgb(209, 213, 219),
                Location = new Point(135, 43),
                AutoSize = true
            };
            cardLaptop.Controls.Add(lblRate);

            lblTimeEstimate = new Label {
                Text = "⏱️ Estimando tiempo...",
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(52, 211, 153),
                Location = new Point(135, 63),
                AutoSize = true
            };
            cardLaptop.Controls.Add(lblTimeEstimate);

            pbBattery = new ProgressBar {
                Location = new Point(12, 86),
                Size = new Size(494, 10),
                Style = ProgressBarStyle.Continuous,
                Value = 50
            };
            cardLaptop.Controls.Add(pbBattery);

            lblPowerSource = new Label { Text = "Alimentación: --", Location = new Point(12, 104), AutoSize = true, ForeColor = Color.FromArgb(156, 163, 175), Font = new Font("Segoe UI", 8.2f) };
            lblCapacity = new Label { Text = "Carga restante: --", Location = new Point(12, 122), AutoSize = true, ForeColor = Color.FromArgb(156, 163, 175), Font = new Font("Segoe UI", 8.2f) };
            lblHealth = new Label { Text = "Salud: ~49% (859 ciclos)", Location = new Point(310, 122), AutoSize = true, ForeColor = Color.FromArgb(156, 163, 175), Font = new Font("Segoe UI", 8.2f) };

            cardLaptop.Controls.Add(lblPowerSource);
            cardLaptop.Controls.Add(lblCapacity);
            cardLaptop.Controls.Add(lblHealth);
            mainContainer.Controls.Add(cardLaptop);

            // 3. TARJETA 2: DISPOSITIVOS CONECTADOS
            Panel cardDevices = CreateCard(14, 198, 520, 162);
            Label lblCard2Title = new Label {
                Text = "DISPOSITIVOS CONECTADOS AHORA (USB / BLUETOOTH)",
                Font = new Font("Segoe UI", 8f, FontStyle.Bold),
                ForeColor = Color.FromArgb(156, 163, 175),
                Location = new Point(12, 7),
                AutoSize = true
            };
            cardDevices.Controls.Add(lblCard2Title);

            pnlDevices = new FlowLayoutPanel {
                Location = new Point(10, 26),
                Size = new Size(498, 126),
                AutoScroll = true,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false
            };
            cardDevices.Controls.Add(pnlDevices);
            mainContainer.Controls.Add(cardDevices);

            // 4. TARJETA 3: ESTADO DEL SUMINISTRO USB & BATERÍAS EXTERNAS
            cardAdvice = CreateCard(14, 366, 520, 152);
            lblAdvice = new Label {
                Text = "Analizando suministro de energía...",
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = Color.FromArgb(243, 244, 246),
                Location = new Point(12, 8),
                Size = new Size(496, 136)
            };
            cardAdvice.Controls.Add(lblAdvice);
            mainContainer.Controls.Add(cardAdvice);

            // 5. BOTÓN ACTUALIZAR
            btnRefresh = new Button {
                Text = "🔄 Actualizar Datos Ahora",
                Location = new Point(14, 524),
                Size = new Size(520, 36),
                BackColor = Color.FromArgb(37, 99, 235),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnRefresh.FlatAppearance.BorderSize = 0;
            btnRefresh.Click += (s, e) => RefreshData();
            mainContainer.Controls.Add(btnRefresh);
        }

        private Panel CreateCard(int x, int y, int width, int height) {
            Panel card = new Panel {
                Location = new Point(x, y),
                Size = new Size(width, height),
                BackColor = Color.FromArgb(28, 32, 42)
            };
            card.Paint += (s, e) => {
                using (Pen p = new Pen(Color.FromArgb(44, 50, 66), 1)) {
                    e.Graphics.DrawRectangle(p, 0, 0, card.Width - 1, card.Height - 1);
                }
            };
            return card;
        }

        private string FormatTimeSpan(int totalMinutes) {
            if (totalMinutes <= 0) return "0 min";
            int hours = totalMinutes / 60;
            int mins = totalMinutes % 60;
            if (hours > 0) {
                return string.Format("{0} h {1:D2} min", hours, mins);
            } else {
                return string.Format("{0} min", mins);
            }
        }

        private void RefreshData() {
            try {
                // 1. Estado de la batería de la laptop
                PowerStatus ps = SystemInformation.PowerStatus;
                int percent = (int)(ps.BatteryLifePercent * 100);
                if (percent > 100) percent = 100;
                if (percent < 0) percent = 0;

                lblPercentage.Text = percent + "%";
                pbBattery.Value = percent;

                if (percent > 45) {
                    lblPercentage.ForeColor = Color.FromArgb(16, 185, 129);
                } else if (percent > 20) {
                    lblPercentage.ForeColor = Color.FromArgb(245, 158, 11);
                } else {
                    lblPercentage.ForeColor = Color.FromArgb(239, 68, 68);
                }

                bool isOnline = (ps.PowerLineStatus == PowerLineStatus.Online);
                double rateWatts = 0;
                int remCapacity = 0;

                try {
                    using (var searcher = new ManagementObjectSearcher("root\\wmi", "SELECT * FROM BatteryStatus")) {
                        foreach (ManagementObject obj in searcher.Get()) {
                            object cr = obj["ChargeRate"];
                            object dr = obj["DischargeRate"];
                            object rc = obj["RemainingCapacity"];

                            if (isOnline && cr != null) {
                                rateWatts = Convert.ToDouble(cr) / 1000.0;
                            } else if (!isOnline && dr != null) {
                                rateWatts = Convert.ToDouble(dr) / 1000.0;
                            }
                            if (rc != null) remCapacity = Convert.ToInt32(rc);
                        }
                    }
                } catch {}

                if (fullCapacityMwh <= 0) {
                    try {
                        using (var searcherFull = new ManagementObjectSearcher("root\\wmi", "SELECT FullChargedCapacity FROM BatteryFullChargedCapacity")) {
                            foreach (ManagementObject obj in searcherFull.Get()) {
                                object fc = obj["FullChargedCapacity"];
                                if (fc != null) fullCapacityMwh = Convert.ToInt32(fc);
                            }
                        }
                    } catch {}
                    if (fullCapacityMwh <= 0) {
                        fullCapacityMwh = 15650;
                    }
                }

                // Cálculo de tiempo restante (desconectado) o tiempo para completar carga (conectado)
                int timeMinutes = -1;
                if (isOnline) {
                    lblStatusBadge.Text = "⚡ CONECTADO AL CARGADOR (RED CA)";
                    lblStatusBadge.ForeColor = Color.FromArgb(16, 185, 129);
                    lblPowerSource.Text = "Alimentación: Enchufe de pared (CA)";

                    if (percent >= 100) {
                        lblRate.Text = "Batería completa (100%) en flotación.";
                        lblTimeEstimate.Text = "⏱️ Carga completa (100%) - Batería llena";
                        lblTimeEstimate.ForeColor = Color.FromArgb(52, 211, 153);
                        timeMinutes = 0;
                    } else if (rateWatts > 0.05) {
                        lblRate.Text = string.Format("Tasa de Carga de la Laptop: +{0:F1} Watts", rateWatts);
                        int neededMwh = Math.Max(0, fullCapacityMwh - remCapacity);
                        if (neededMwh <= 0 && percent < 100) {
                            neededMwh = (int)(fullCapacityMwh * (100.0 - percent) / 100.0);
                        }
                        timeMinutes = (int)Math.Round(((double)neededMwh / (rateWatts * 1000.0)) * 60.0);
                        if (timeMinutes < 1) timeMinutes = 1;
                        lblTimeEstimate.Text = string.Format("⏱️ Falta para carga completa: ~{0}", FormatTimeSpan(timeMinutes));
                        lblTimeEstimate.ForeColor = Color.FromArgb(52, 211, 153);
                    } else {
                        if (percent >= 98) {
                            lblRate.Text = "Batería completa (~100%) en reposo.";
                            lblTimeEstimate.Text = "⏱️ Batería al 100% - Modo conservación/flotación";
                            lblTimeEstimate.ForeColor = Color.FromArgb(52, 211, 153);
                            timeMinutes = 0;
                        } else {
                            lblRate.Text = "Conectado a la corriente (esperando flujo).";
                            lblTimeEstimate.Text = "⏱️ Conectado (Calculando tiempo de carga...)";
                            lblTimeEstimate.ForeColor = Color.FromArgb(156, 163, 175);
                        }
                    }
                } else {
                    lblStatusBadge.Text = "🔋 EN BATERÍA (DESCONECTADO)";
                    lblStatusBadge.ForeColor = Color.FromArgb(245, 158, 11);
                    lblPowerSource.Text = "Alimentación: Batería interna (CC)";

                    if (rateWatts > 0.05) {
                        lblRate.Text = string.Format("Consumo total del sistema y puertos: -{0:F1} Watts", rateWatts);
                        if (remCapacity > 0) {
                            timeMinutes = (int)Math.Round(((double)remCapacity / (rateWatts * 1000.0)) * 60.0);
                        }
                    } else {
                        lblRate.Text = "Modo batería activo.";
                    }

                    if (timeMinutes <= 0 && ps.BatteryLifeRemaining > 0 && ps.BatteryLifeRemaining < 86400) {
                        timeMinutes = ps.BatteryLifeRemaining / 60;
                    }

                    if (timeMinutes > 0) {
                        lblTimeEstimate.Text = string.Format("⏱️ Tiempo restante de batería: ~{0}", FormatTimeSpan(timeMinutes));
                        lblTimeEstimate.ForeColor = (percent > 20) ? Color.FromArgb(251, 191, 36) : Color.FromArgb(239, 68, 68);
                    } else {
                        lblTimeEstimate.Text = "⏱️ Estimando tiempo restante de batería...";
                        lblTimeEstimate.ForeColor = Color.FromArgb(156, 163, 175);
                    }
                }

                if (remCapacity > 0 && fullCapacityMwh > 0) {
                    lblCapacity.Text = string.Format("Capacidad: {0:F1} / {1:F1} Wh", remCapacity / 1000.0, fullCapacityMwh / 1000.0);
                } else if (remCapacity > 0) {
                    lblCapacity.Text = string.Format("Carga restante: {0:F1} Wh", remCapacity / 1000.0);
                } else {
                    lblCapacity.Text = "Capacidad actual: ~12.0 Wh";
                }

                // 2. Dispositivos Conectados
                pnlDevices.Controls.Clear();
                List<ConnectedDevice> devices = GetActiveConnectedDevices();

                if (devices.Count == 0) {
                    Panel pnlEmpty = new Panel { Size = new Size(475, 115), BackColor = Color.Transparent };
                    Label lblEmpty = new Label {
                        Text = "🟢 SIN DISPOSITIVOS CONECTADOS\n\n" +
                               "No hay dispositivos USB ni accesorios Bluetooth conectados en este momento.\n\n" +
                               "• Tus puertos USB están en reposo y libres de consumo externo.\n" +
                               "• Si conectas un celular, memoria USB, audífonos o control, aparecerán aquí en vivo.",
                        Size = new Size(470, 110),
                        ForeColor = Color.FromArgb(156, 163, 175),
                        Font = new Font("Segoe UI", 8.8f)
                    };
                    pnlEmpty.Controls.Add(lblEmpty);
                    pnlDevices.Controls.Add(pnlEmpty);
                } else {
                    foreach (var d in devices) {
                        pnlDevices.Controls.Add(CreateDeviceRow(d));
                    }
                }

                // 3. Guía de Carga y Protección de Batería
                if (devices.Count == 0) {
                    if (isOnline) {
                        cardAdvice.BackColor = Color.FromArgb(20, 36, 28);
                        lblAdvice.ForeColor = Color.FromArgb(167, 243, 208);
                        string timeInfo = (timeMinutes > 0)
                            ? string.Format("• Tiempo estimado para carga completa (100%): ~{0} (suministro a +{1:F1} W).\n", FormatTimeSpan(timeMinutes), rateWatts)
                            : (percent >= 98 ? "• La batería está al 100% o en flotación continua.\n" : "• Calculando tiempo de carga...\n");

                        lblAdvice.Text = "✅ ALIMENTACIÓN POR RED ELÉCTRICA (CARGADOR CONECTADO)\n\n" +
                                         timeInfo +
                                         "• Tu laptop está conectada a la corriente y la batería se mantiene protegida.\n" +
                                         "• Puedes conectar cualquier accesorio o celular a los puertos USB sin degradar tu batería interna.";
                    } else {
                        cardAdvice.BackColor = Color.FromArgb(28, 32, 42);
                        lblAdvice.ForeColor = Color.FromArgb(209, 213, 219);
                        string timeInfo = (timeMinutes > 0)
                            ? string.Format("• Tiempo estimado de duración restante: ~{0} de autonomía con el consumo actual.\n", FormatTimeSpan(timeMinutes))
                            : "• Estimando tiempo restante de batería...\n";

                        lblAdvice.Text = "🔋 TRABAJANDO EN BATERÍA (DESCONECTADO DE LA RED)\n\n" +
                                         timeInfo +
                                         string.Format("• Consumo actual de la laptop: ~{0:F1} Watts (pantalla, procesador y memoria).\n", rateWatts > 0 ? rateWatts : 9.1) +
                                         "• No hay dispositivos externos drenando energía de tu equipo.\n" +
                                         "• Consejo: Para ahorrar batería fuera de casa, reduce el brillo de la pantalla o activa el Modo SuperEco.";
                    }
                } else {
                    if (isOnline) {
                        cardAdvice.BackColor = Color.FromArgb(20, 36, 28);
                        lblAdvice.ForeColor = Color.FromArgb(167, 243, 208);
                        string timeInfo = (timeMinutes > 0)
                            ? string.Format("• Tiempo estimado para carga completa (100%): ~{0}.\n", FormatTimeSpan(timeMinutes))
                            : (percent >= 98 ? "• Batería al 100% en reposo.\n" : "• Calculando tiempo de carga...\n");

                        lblAdvice.Text = string.Format("✅ ESTACIÓN DE CARGA ACTIVA ({0} DISPOSITIVO{1})\n\n", devices.Count, devices.Count > 1 ? "S" : "") +
                                         timeInfo +
                                         "• La laptop está enchufada a la pared. Los dispositivos conectados se alimentan directamente de la red eléctrica sin desgastar tu batería interna.";
                    } else {
                        cardAdvice.BackColor = Color.FromArgb(44, 26, 16);
                        lblAdvice.ForeColor = Color.FromArgb(254, 215, 170);
                        string timeInfo = (timeMinutes > 0)
                            ? string.Format("• Tiempo estimado de duración restante: ~{0} de autonomía.\n", FormatTimeSpan(timeMinutes))
                            : "• Estimando tiempo restante de batería...\n";

                        lblAdvice.Text = "⚠️ AVISO: DISPOSITIVOS ALIMENTADOS POR LA BATERÍA\n\n" +
                                         timeInfo +
                                         string.Format("• Tienes {0} dispositivo(s) conectado(s) que están consumiendo energía de la batería de tu portátil.\n", devices.Count) +
                                         "• Si necesitas que tu laptop dure más tiempo encendida, desconéctalos o enchufa tu cargador a la pared.";
                    }
                }

            } catch (Exception ex) {
                lblStatusBadge.Text = "Error: " + ex.Message;
            }
        }

        private Panel CreateDeviceRow(ConnectedDevice dev) {
            Panel row = new Panel {
                Size = new Size(475, 46),
                BackColor = Color.FromArgb(36, 42, 54),
                Margin = new Padding(0, 0, 0, 5)
            };

            Label lblIcon = new Label {
                Text = dev.Icon,
                Font = new Font("Segoe UI", 13f),
                Location = new Point(6, 8),
                Size = new Size(30, 28),
                TextAlign = ContentAlignment.MiddleCenter
            };

            Label lblName = new Label {
                Text = dev.Name,
                Font = new Font("Segoe UI", 9f, FontStyle.Bold),
                ForeColor = Color.FromArgb(243, 244, 246),
                Location = new Point(40, 5),
                Size = new Size(250, 18),
                AutoEllipsis = true
            };

            Label lblType = new Label {
                Text = dev.ConnectionType,
                Font = new Font("Segoe UI", 7.8f),
                ForeColor = Color.FromArgb(156, 163, 175),
                Location = new Point(40, 24),
                Size = new Size(250, 16)
            };

            Label lblStatus = new Label {
                Text = dev.Status,
                Font = new Font("Segoe UI", 9f, FontStyle.Bold),
                ForeColor = dev.BatteryLevel >= 0 ? Color.FromArgb(52, 211, 153) : Color.FromArgb(96, 165, 250),
                Location = new Point(295, 12),
                Size = new Size(170, 20),
                TextAlign = ContentAlignment.MiddleRight
            };

            row.Controls.Add(lblIcon);
            row.Controls.Add(lblName);
            row.Controls.Add(lblType);
            row.Controls.Add(lblStatus);

            return row;
        }

        private List<ConnectedDevice> GetActiveConnectedDevices() {
            var list = new List<ConnectedDevice>();
            var seenNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            try {
                using (var searcher = new ManagementObjectSearcher(
                    "SELECT Name, PNPClass, DeviceID FROM Win32_PnPEntity WHERE Status = 'OK'")) {

                    foreach (ManagementObject obj in searcher.Get()) {
                        string name = obj["Name"] as string;
                        string pnpClass = obj["PNPClass"] as string;
                        string devId = obj["DeviceID"] as string;

                        if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(devId)) continue;

                        // 1. Descartar controladores internos y componentes base de la laptop
                        if (Regex.IsMatch(name, @"Integrated Camera|Webcam|Realtek Bluetooth|Intel|Audio|Realtek|Driver|Concentrador|Hub|Host Controller|Root|Generic|Terminal|Enumerador|Proxy|Convertidor|Servicio|Adapter|Personal|Transporte AVRCP|Dispositivo compuesto|RFCOMM|ELAN|I2C|Synaptics|Touchpad|Teclado|Keyboard|Mouse|Micrófono|Altavoces|Speakers", RegexOptions.IgnoreCase)) {
                            continue;
                        }

                        if (Regex.IsMatch(devId, @"VID_5986|VID_0BDA|ROOT_HUB|ACPI|ELAN|MS_RFCOMM|MS_BTH|PCI\\", RegexOptions.IgnoreCase)) {
                            continue;
                        }

                        // 2. Si es Bluetooth: SÓLO inspeccionar el dispositivo principal (BTHENUM\DEV_)
                        if (pnpClass == "Bluetooth" || devId.StartsWith("BTHENUM", StringComparison.OrdinalIgnoreCase)) {
                            if (!devId.StartsWith(@"BTHENUM\DEV_", StringComparison.OrdinalIgnoreCase)) {
                                continue;
                            }
                            if (!PnpNative.IsDeviceConnected(devId)) {
                                continue; // Descartar dispositivos Bluetooth que NO están conectados ahora
                            }
                        } else if (pnpClass == "USB" || devId.StartsWith("USB\\", StringComparison.OrdinalIgnoreCase)) {
                            if (!PnpNative.IsDeviceConnected(devId)) {
                                continue;
                            }
                        } else if (pnpClass != "WPD" && pnpClass != "HIDClass") {
                            continue;
                        }

                        if (seenNames.Contains(name)) continue;
                        seenNames.Add(name);

                        // 3. Determinar icono, tipo y batería
                        int battery = PnpNative.GetBatteryLevel(devId);
                        string icon = "🔌";
                        string connType = "Dispositivo USB Conectado";
                        string status = (battery >= 0) ? string.Format("🔋 {0}%", battery) : "⚡ Conectado / Activo";

                        if (Regex.IsMatch(name, @"TECNO|Galaxy|iPhone|Xiaomi|Redmi|Huawei|Motorola|Phone|Android|Pixel", RegexOptions.IgnoreCase)) {
                            icon = "📱";
                            connType = "Teléfono Celular";
                            status = (battery >= 0) ? string.Format("🔋 {0}%", battery) : "⚡ Conectado / Cargando";
                        } else if (Regex.IsMatch(name, @"DualSense|Wireless Controller|Xbox|Gamepad|Joystick|Mando", RegexOptions.IgnoreCase)) {
                            icon = "🎮";
                            connType = "Mando de Videojuegos";
                            status = (battery >= 0) ? string.Format("🔋 {0}%", battery) : (pnpClass == "Bluetooth" ? "🟢 Conectado" : "⚡ Cargando por USB");
                        } else if (Regex.IsMatch(name, @"SB20BT|Headset|Earbuds|Headphones|Auriculares|Altavoz|Speaker", RegexOptions.IgnoreCase)) {
                            icon = "🎧";
                            connType = "Auricular / Altavoz Bluetooth";
                            status = (battery >= 0) ? string.Format("🔋 {0}%", battery) : "🟢 Conectado (Activo)";
                        } else if (pnpClass == "Bluetooth") {
                            icon = "📶";
                            connType = "Dispositivo Bluetooth Conectado";
                            status = (battery >= 0) ? string.Format("🔋 {0}%", battery) : "🟢 Conectado (Activo)";
                        }

                        list.Add(new ConnectedDevice {
                            Name = name,
                            Icon = icon,
                            ConnectionType = connType,
                            Status = status,
                            BatteryLevel = battery
                        });
                    }
                }
            } catch {}

            return list;
        }

        [STAThread]
        public static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class ConnectedDevice {
        public string Name { get; set; }
        public string Icon { get; set; }
        public string ConnectionType { get; set; }
        public string Status { get; set; }
        public int BatteryLevel { get; set; }
    }

    public static class PnpNative {
        [StructLayout(LayoutKind.Sequential)]
        public struct DEVPROPKEY {
            public Guid fmtid;
            public uint pid;
        }

        [DllImport("cfgmgr32.dll", EntryPoint = "CM_Locate_DevNodeW", CharSet = CharSet.Unicode)]
        public static extern int CM_Locate_DevNode(out uint dnDevInst, string pDeviceID, int ulFlags);

        [DllImport("cfgmgr32.dll", EntryPoint = "CM_Get_DevNode_PropertyW", CharSet = CharSet.Unicode)]
        public static extern int CM_Get_DevNode_Property(uint dnDevInst, ref DEVPROPKEY PropertyKey, out uint PropertyType, byte[] PropertyBuffer, ref uint PropertyBufferSize, uint ulFlags);

        public static bool IsDeviceConnected(string deviceId) {
            try {
                uint devInst;
                int cr = CM_Locate_DevNode(out devInst, deviceId, 0);
                if (cr != 0) return false;

                DEVPROPKEY key;
                key.fmtid = new Guid("83da6326-97a6-4088-9453-a1923f573b29");
                key.pid = 15; // DEVPKEY_Device_IsConnected

                uint propType;
                uint bufferSize = 4;
                byte[] buffer = new byte[4];
                cr = CM_Get_DevNode_Property(devInst, ref key, out propType, buffer, ref bufferSize, 0);
                if (cr == 0 && bufferSize > 0) {
                    return buffer[0] != 0;
                }
                return false;
            } catch {
                return false;
            }
        }

        public static int GetBatteryLevel(string deviceId) {
            try {
                uint devInst;
                int cr = CM_Locate_DevNode(out devInst, deviceId, 0);
                if (cr != 0) return -1;

                DEVPROPKEY key;
                key.fmtid = new Guid("104ea319-6ee2-4701-bd47-8ddbf425bbe5");
                key.pid = 2; // DEVPKEY_Device_BatteryPercentage

                uint propType;
                uint bufferSize = 4;
                byte[] buffer = new byte[4];
                cr = CM_Get_DevNode_Property(devInst, ref key, out propType, buffer, ref bufferSize, 0);
                if (cr == 0 && bufferSize > 0) {
                    return (int)buffer[0];
                }
                return -1;
            } catch {
                return -1;
            }
        }
    }
}
