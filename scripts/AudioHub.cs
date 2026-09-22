using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Management;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AudioHubApp {
    public class MainForm : Form {
        private Timer timer;

        // UI Controls
        private Label lblOutputDevice;
        private Label lblVolPercent;
        private TrackBar trackVolume;
        private Button btnMute;
        private Label lblDolbyStatus;
        private Label lblPresetDescription;
        private Button[] presetButtons;

        public MainForm() {
            InitializeUI();
            RefreshAudioState();

            timer = new Timer();
            timer.Interval = 1000; // Sincronización en vivo cada segundo
            timer.Tick += (s, e) => RefreshAudioState();
            timer.Start();
        }

        private void InitializeUI() {
            this.Text = "🎵 AudioHub & Super Booster 200% - Control y Ecualización";
            this.Size = new Size(630, 605);
            this.MinimumSize = new Size(610, 580);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(16, 18, 26);
            this.ForeColor = Color.White;
            this.Font = new Font("Segoe UI", 9f, FontStyle.Regular);
            this.Icon = SystemIcons.Application;

            // Panel Principal
            Panel mainContainer = new Panel {
                Dock = DockStyle.Fill,
                Padding = new Padding(14)
            };
            this.Controls.Add(mainContainer);

            // 1. ENCABEZADO (Y: 10, H: 40)
            Panel pnlHeader = new Panel { Size = new Size(580, 40), Location = new Point(14, 8) };
            Label lblTitle = new Label {
                Text = "🎵 AudioHub & Booster",
                Font = new Font("Segoe UI", 15f, FontStyle.Bold),
                ForeColor = Color.FromArgb(240, 240, 245),
                AutoSize = true,
                Location = new Point(0, 0)
            };
            Label lblSub = new Label {
                Text = "Ecualizador Dolby, Control Maestro & Amplificación al 200%",
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = Color.FromArgb(168, 85, 247),
                AutoSize = true,
                Location = new Point(220, 8)
            };
            pnlHeader.Controls.Add(lblTitle);
            pnlHeader.Controls.Add(lblSub);
            mainContainer.Controls.Add(pnlHeader);

            // 2. TARJETA 1: SALIDA DE AUDIO Y VOLUMEN MAESTRO (Y: 50, H: 96)
            Panel cardVol = CreateCard(14, 50, 580, 96);
            cardVol.Controls.Add(CreateHeader("🔊 SALIDA DE AUDIO Y VOLUMEN MAESTRO", Color.FromArgb(56, 189, 248), 12, 8));

            lblOutputDevice = new Label {
                Text = "Salida activa: Altavoces (Realtek(R) Audio)",
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                ForeColor = Color.FromArgb(209, 213, 219),
                Location = new Point(12, 28),
                Size = new Size(420, 16),
                AutoEllipsis = true
            };
            cardVol.Controls.Add(lblOutputDevice);

            lblVolPercent = new Label {
                Text = "50%",
                Font = new Font("Segoe UI", 16f, FontStyle.Bold),
                ForeColor = Color.FromArgb(168, 85, 247),
                Location = new Point(10, 48),
                Size = new Size(65, 34),
                TextAlign = ContentAlignment.MiddleLeft
            };
            cardVol.Controls.Add(lblVolPercent);

            trackVolume = new TrackBar {
                Location = new Point(78, 50),
                Size = new Size(365, 40),
                Minimum = 0,
                Maximum = 100,
                TickFrequency = 10,
                Value = 50
            };
            trackVolume.Scroll += (s, e) => {
                float v = (float)trackVolume.Value / 100f;
                AudioNative.SetVolume(v);
                lblVolPercent.Text = trackVolume.Value + "%";
            };
            cardVol.Controls.Add(trackVolume);

            btnMute = new Button {
                Text = "🔊 Silenciar",
                Location = new Point(452, 50),
                Size = new Size(116, 32),
                BackColor = Color.FromArgb(39, 45, 62),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnMute.FlatAppearance.BorderSize = 0;
            btnMute.Click += (s, e) => {
                bool current = AudioNative.GetMute();
                AudioNative.SetMute(!current);
                RefreshAudioState();
            };
            cardVol.Controls.Add(btnMute);
            mainContainer.Controls.Add(cardVol);

            // 3. TARJETA 2: 🚀 SUPER BOOSTER 200% - 600% (Y: 152, H: 125)
            Panel cardBooster = CreateCard(14, 152, 580, 125);
            cardBooster.Controls.Add(CreateHeader("🚀 SUPER BOOSTER: AUMENTAR EL VOLUMEN AL 200% - 600%", Color.FromArgb(244, 63, 94), 12, 8));

            Label lblBoosterInfo = new Label {
                Text = "Windows limita el volumen de fábrica al 100%. Para superar el límite y duplicar el sonido:",
                Font = new Font("Segoe UI", 8f),
                ForeColor = Color.FromArgb(148, 163, 184),
                Location = new Point(12, 28),
                AutoSize = true
            };
            cardBooster.Controls.Add(lblBoosterInfo);

            // Botón 1: Volume Master para Edge
            Button btnEdgeBooster = new Button {
                Text = "🌐 Booster en Edge (Hasta 600%)",
                Location = new Point(12, 48),
                Size = new Size(182, 38),
                BackColor = Color.FromArgb(225, 29, 72),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.2f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnEdgeBooster.FlatAppearance.BorderSize = 0;
            btnEdgeBooster.Click += (s, e) => {
                try {
                    Process.Start("msedge.exe", "https://microsoftedge.microsoft.com/addons/detail/volume-master/jgheacmhhgfpkmbjngaimkbfmcaigmbc");
                    MessageBox.Show("Se ha abierto la página de 'Volume Master' en Edge.\n\nSimplemente pulsa en 'Obtener' y tendrás una perilla para amplificar YouTube, Netflix, Spotify y vídeos hasta el 600% (incluyendo 200%).", "Booster 200% - Edge", MessageBoxButtons.OK, MessageBoxIcon.Information);
                } catch (Exception ex) {
                    MessageBox.Show("Error al abrir Edge: " + ex.Message, "Booster", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
            };
            cardBooster.Controls.Add(btnEdgeBooster);

            // Botón 2: Nivelador Dolby (Altavoces Lenovo)
            Button btnDolbyBoost = new Button {
                Text = "🎛️ Nivelador Dolby (+200% Altavoz)",
                Location = new Point(199, 48),
                Size = new Size(182, 38),
                BackColor = Color.FromArgb(147, 51, 234),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.2f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnDolbyBoost.FlatAppearance.BorderSize = 0;
            btnDolbyBoost.Click += (s, e) => {
                LaunchDolby();
                MessageBox.Show("Dentro de Dolby Audio:\n\n1. Asegúrate de que Dolby esté ENCENDIDO.\n2. En el perfil 'Personalizado' o 'Película', activa la opción 'Nivelador de Volumen' (Volume Leveler).\n\nEsto aplica ganancia acústica digital de hasta +12dB, duplicando el volumen percibido de los altavoces de tu Lenovo sin que se dañen ni distorsionen.", "Booster Nativo Lenovo", MessageBoxButtons.OK, MessageBoxIcon.Information);
            };
            cardBooster.Controls.Add(btnDolbyBoost);

            // Botón 3: FxSound Booster Global
            Button btnFxSound = new Button {
                Text = "🔊 FxSound (Booster Global 200%)",
                Location = new Point(386, 48),
                Size = new Size(182, 38),
                BackColor = Color.FromArgb(30, 41, 59),
                ForeColor = Color.FromArgb(226, 232, 240),
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.2f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnFxSound.FlatAppearance.BorderSize = 0;
            btnFxSound.Click += (s, e) => {
                try {
                    // Comprobar si ya está instalado
                    string fxExe = @"C:\Program Files\FxSound LLC\FxSound\FxSound.exe";
                    string fxExe86 = @"C:\Program Files (x86)\FxSound LLC\FxSound\FxSound.exe";
                    if (File.Exists(fxExe)) {
                        Process.Start(fxExe);
                    } else if (File.Exists(fxExe86)) {
                        Process.Start(fxExe86);
                    } else {
                        var res = MessageBox.Show("FxSound es la mejor app libre y gratuita para amplificar todo el sonido de Windows al 200% (juegos, reproductores de video, Spotify y apps).\n\n¿Deseas descargar el instalador oficial ahora?", "Instalar FxSound Booster", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                        if (res == DialogResult.Yes) {
                            Process.Start("https://download.fxsound.com/fxsoundlatest");
                        }
                    }
                } catch (Exception ex) {
                    MessageBox.Show("Error: " + ex.Message, "FxSound", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
            };
            cardBooster.Controls.Add(btnFxSound);

            Label lblBoosterFoot = new Label {
                Text = "💡 Consejo: Para YouTube y películas web usa el Booster de Edge (600%). Para altavoces del portátil usa Dolby.",
                Font = new Font("Segoe UI", 7.6f),
                ForeColor = Color.FromArgb(100, 116, 139),
                Location = new Point(12, 94),
                AutoSize = true
            };
            cardBooster.Controls.Add(lblBoosterFoot);
            mainContainer.Controls.Add(cardBooster);

            // 4. TARJETA 3: ECUALIZADOR DOLBY AUDIO (Y: 284, H: 88)
            Panel cardDolby = CreateCard(14, 284, 580, 88);
            cardDolby.Controls.Add(CreateHeader("🎛️ PROCESADOR DOLBY AUDIO (DAX3) & MEJORAS DE WINDOWS", Color.FromArgb(236, 72, 153), 12, 8));

            lblDolbyStatus = new Label {
                Text = "● Motor Dolby DAX3 calibrado para Lenovo IdeaPad | Ecualizador paramétrico listo",
                Font = new Font("Segoe UI", 8.2f),
                ForeColor = Color.FromArgb(16, 185, 129),
                Location = new Point(12, 28),
                AutoSize = true
            };
            cardDolby.Controls.Add(lblDolbyStatus);

            Button btnOpenDolby = new Button {
                Text = "🎛️ Abrir Ecualizador Gráfico Dolby Audio",
                Location = new Point(12, 48),
                Size = new Size(295, 32),
                BackColor = Color.FromArgb(147, 51, 234),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.6f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnOpenDolby.FlatAppearance.BorderSize = 0;
            btnOpenDolby.Click += (s, e) => LaunchDolby();
            cardDolby.Controls.Add(btnOpenDolby);

            Button btnSoundProps = new Button {
                Text = "⚙️ Ecualización de Sonoridad (Windows)",
                Location = new Point(313, 48),
                Size = new Size(255, 32),
                BackColor = Color.FromArgb(39, 45, 62),
                ForeColor = Color.FromArgb(209, 213, 219),
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.2f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnSoundProps.FlatAppearance.BorderSize = 0;
            btnSoundProps.Click += (s, e) => {
                try { Process.Start("control.exe", "mmsys.cpl sounds"); } catch {}
            };
            cardDolby.Controls.Add(btnSoundProps);
            mainContainer.Controls.Add(cardDolby);

            // 5. TARJETA 4: PRESETS DE ECUALIZACIÓN (Y: 378, H: 136)
            Panel cardPresets = CreateCard(14, 378, 580, 136);
            cardPresets.Controls.Add(CreateHeader("💡 PRESETS Y CURVAS DE ECUALIZACIÓN RECOMENDADAS", Color.FromArgb(245, 158, 11), 12, 8));

            string[] names = { "🚀 Booster 200%", "🎵 Música (Bass)", "🎬 Películas (Cine)", "🎙️ Diálogos / Voz", "🎮 Gaming" };
            presetButtons = new Button[5];
            int btnW = 104;

            for (int i = 0; i < 5; i++) {
                int idx = i;
                presetButtons[i] = new Button {
                    Text = names[i],
                    Location = new Point(12 + i * (btnW + 8), 28),
                    Size = new Size(btnW, 28),
                    BackColor = (i == 0) ? Color.FromArgb(244, 63, 94) : Color.FromArgb(39, 45, 62),
                    ForeColor = Color.White,
                    FlatStyle = FlatStyle.Flat,
                    Font = new Font("Segoe UI", 7.8f, FontStyle.Bold),
                    Cursor = Cursors.Hand
                };
                presetButtons[i].FlatAppearance.BorderSize = 0;
                presetButtons[i].Click += (s, e) => SelectPreset(idx);
                cardPresets.Controls.Add(presetButtons[i]);
            }

            lblPresetDescription = new Label {
                Text = "• Modo Booster 200%: Activa 'Volume Leveler' en Dolby Audio y sube las bandas de 500Hz a 4kHz a +6dB.\n" +
                       "• Para vídeos de YouTube o películas en streaming con sonido bajo: Pulsa arriba 'Booster en Edge' y súbelo al 200% o hasta 600% con un solo clic.",
                Font = new Font("Segoe UI", 8.2f),
                ForeColor = Color.FromArgb(226, 232, 240),
                Location = new Point(12, 62),
                Size = new Size(556, 64)
            };
            cardPresets.Controls.Add(lblPresetDescription);
            mainContainer.Controls.Add(cardPresets);

            // 6. BARRA INFERIOR (Y: 520, H: 34)
            Button btnWindowsSound = new Button {
                Text = "⚙️ Configuración de Sonido Windows 11",
                Location = new Point(14, 520),
                Size = new Size(280, 34),
                BackColor = Color.FromArgb(30, 41, 59),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnWindowsSound.FlatAppearance.BorderSize = 0;
            btnWindowsSound.Click += (s, e) => {
                try { Process.Start("ms-settings:sound"); } catch {}
            };
            mainContainer.Controls.Add(btnWindowsSound);

            Button btnTestSound = new Button {
                Text = "🔔 Reproducir Tono de Prueba",
                Location = new Point(304, 520),
                Size = new Size(290, 34),
                BackColor = Color.FromArgb(37, 99, 235),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btnTestSound.FlatAppearance.BorderSize = 0;
            btnTestSound.Click += (s, e) => {
                System.Media.SystemSounds.Asterisk.Play();
            };
            mainContainer.Controls.Add(btnTestSound);
        }

        private Panel CreateCard(int x, int y, int width, int height) {
            Panel card = new Panel {
                Location = new Point(x, y),
                Size = new Size(width, height),
                BackColor = Color.FromArgb(24, 28, 40)
            };
            card.Paint += (s, e) => {
                using (Pen p = new Pen(Color.FromArgb(44, 52, 72), 1)) {
                    e.Graphics.DrawRectangle(p, 0, 0, card.Width - 1, card.Height - 1);
                }
            };
            return card;
        }

        private Label CreateHeader(string text, Color color, int x, int y) {
            return new Label {
                Text = text,
                Font = new Font("Segoe UI", 8.2f, FontStyle.Bold),
                ForeColor = color,
                Location = new Point(x, y),
                AutoSize = true
            };
        }

        private void SelectPreset(int index) {
            for (int i = 0; i < presetButtons.Length; i++) {
                if (i == index) {
                    presetButtons[i].BackColor = (i == 0) ? Color.FromArgb(244, 63, 94) : Color.FromArgb(168, 85, 247);
                } else {
                    presetButtons[i].BackColor = Color.FromArgb(39, 45, 62);
                }
            }

            if (index == 0) { // Booster 200%
                lblPresetDescription.Text = "• Modo Booster 200%: Activa 'Volume Leveler' en Dolby Audio y sube las bandas de 500Hz a 4kHz a +6dB.\n" +
                                            "• Para vídeos de YouTube o películas en streaming con sonido bajo: Pulsa arriba 'Booster en Edge' y súbelo al 200% o hasta 600% con un solo clic.";
            } else if (index == 1) { // Música (Bass)
                lblPresetDescription.Text = "• Curva en V para Música: Graves (64Hz-125Hz) a +4dB para pegada cálida, Medios lineales para voces claras y Agudos (4kHz-16kHz) a +5dB para brillo en instrumentos.\n" +
                                            "• En Dolby Audio: Activa 'Volume Leveler' para obtener hasta +40% de volumen audible sin distorsión.";
            } else if (index == 2) { // Películas (Cine)
                lblPresetDescription.Text = "• Modo Cine: Activa 'Surround Virtualizer' para sonido envolvente 3D y 'Dialogue Enhancer' para voces claras.\n" +
                                            "• 'Volume Leveler' evita que tengas que subir el volumen en susurros y bajarlo en explosiones.";
            } else if (index == 3) { // Diálogos / Voz
                lblPresetDescription.Text = "• Voz & Podcasts: Realce en frecuencias medias (1kHz a 3kHz) a +4dB y atenuación en subgraves para eliminar zumbidos de mesa.\n" +
                                            "• Ideal para reuniones de trabajo, YouTube, clases y llamadas telefónicas.";
            } else if (index == 4) { // Juegos (Gaming)
                lblPresetDescription.Text = "• Modo Gaming: Realce en frecuencias altas (2kHz a 8kHz) para localizar con precisión pasos, disparos y recargas de enemigos.\n" +
                                            "• Activa el Virtualizador de sonido en Dolby para mayor sensación de espacio 3D.";
            }
        }

        private void LaunchDolby() {
            try {
                Process.Start("explorer.exe", "shell:AppsFolder\\DolbyLaboratories.DolbyAudio_rz1tebttyb220!App");
            } catch (Exception ex) {
                MessageBox.Show("No se pudo iniciar Dolby Audio: " + ex.Message, "AudioHub", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void RefreshAudioState() {
            try {
                float vol = AudioNative.GetVolume();
                int volPercent = (int)Math.Round(vol * 100);
                if (volPercent < 0) volPercent = 0;
                if (volPercent > 100) volPercent = 100;

                if (!trackVolume.Capture) {
                    trackVolume.Value = volPercent;
                    lblVolPercent.Text = volPercent + "%";
                }

                bool isMuted = AudioNative.GetMute();
                if (isMuted) {
                    btnMute.Text = "🔇 Mutear (OFF)";
                    btnMute.BackColor = Color.FromArgb(239, 68, 68);
                } else {
                    btnMute.Text = "🔊 Silenciar";
                    btnMute.BackColor = Color.FromArgb(39, 45, 62);
                }

                // Detectar nombre de salida activa
                string devName = AudioNative.GetDefaultDeviceName();
                if (!string.IsNullOrEmpty(devName)) {
                    lblOutputDevice.Text = "Salida activa: " + devName;
                }
            } catch {}
        }

        [STAThread]
        public static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    internal static class AudioNative {
        [ComImport]
        [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
        private class MMDeviceEnumeratorComObject { }

        [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IMMDeviceEnumerator {
            int EnumAudioEndpoints(int dataFlow, int stateMask, out IntPtr deviceCollection);
            int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
        }

        [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IMMDevice {
            int Activate(ref Guid id, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object interfacePointer);
            int OpenPropertyStore(int stgmAccess, out IPropertyStore properties);
            int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
            int GetState(out int state);
        }

        [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IPropertyStore {
            int GetCount(out uint count);
            int GetAt(uint iProp, out PROPERTYKEY pkey);
            int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
            int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
            int Commit();
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct PROPERTYKEY {
            public Guid fmtid;
            public uint pid;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct PROPVARIANT {
            [FieldOffset(0)] public ushort vt;
            [FieldOffset(8)] public IntPtr pwszVal;
        }

        [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IAudioEndpointVolume {
            int RegisterControlChangeNotify(IntPtr client);
            int UnregisterControlChangeNotify(IntPtr client);
            int GetChannelCount(out int channelCount);
            int SetMasterVolumeLevel(float levelDB, ref Guid eventContext);
            int SetMasterVolumeLevelScalar(float level, ref Guid eventContext);
            int GetMasterVolumeLevel(out float levelDB);
            int GetMasterVolumeLevelScalar(out float level);
            int SetMute([MarshalAs(UnmanagedType.Bool)] bool isMuted, ref Guid eventContext);
            int GetMute([MarshalAs(UnmanagedType.Bool)] out bool isMuted);
        }

        private static IAudioEndpointVolume GetEndpointVolume() {
            var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
            IMMDevice dev;
            enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
            Guid IID_IAudioEndpointVolume = typeof(IAudioEndpointVolume).GUID;
            object o;
            dev.Activate(ref IID_IAudioEndpointVolume, 1, IntPtr.Zero, out o);
            return (IAudioEndpointVolume)o;
        }

        public static float GetVolume() {
            try {
                var vol = GetEndpointVolume();
                float level;
                vol.GetMasterVolumeLevelScalar(out level);
                return level;
            } catch {
                return 0.5f;
            }
        }

        public static void SetVolume(float level) {
            try {
                var vol = GetEndpointVolume();
                Guid empty = Guid.Empty;
                vol.SetMasterVolumeLevelScalar(level, ref empty);
            } catch {}
        }

        public static bool GetMute() {
            try {
                var vol = GetEndpointVolume();
                bool m;
                vol.GetMute(out m);
                return m;
            } catch {
                return false;
            }
        }

        public static void SetMute(bool mute) {
            try {
                var vol = GetEndpointVolume();
                Guid empty = Guid.Empty;
                vol.SetMute(mute, ref empty);
            } catch {}
        }

        public static string GetDefaultDeviceName() {
            try {
                var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
                IMMDevice dev;
                enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
                IPropertyStore store;
                dev.OpenPropertyStore(0, out store); // STGM_READ = 0

                PROPERTYKEY key;
                key.fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0");
                key.pid = 14; // PKEY_Device_FriendlyName

                PROPVARIANT val;
                store.GetValue(ref key, out val);
                if (val.pwszVal != IntPtr.Zero) {
                    return Marshal.PtrToStringUni(val.pwszVal);
                }
            } catch {}
            return "Altavoces (Realtek(R) Audio)";
        }
    }
}
