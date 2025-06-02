# 🚀 Hyprland Dotfiles

Una configuración completa y moderna de Hyprland con soporte VPN, gaming, desarrollo y productividad.

![Desktop](screenshots/desktop.png)

## ✨ Características

- 🎨 **Tema Catppuccin Mocha** - Colores modernos y elegantes
- 🔒 **Sistema VPN completo** - Soporte para múltiples proveedores
- 🎮 **Optimizado para gaming** - GameMode, MangoHud, Steam
- 💻 **Entorno de desarrollo** - VS Code, Git, herramientas CLI
- 🐟 **Fish shell** con Starship prompt
- 📊 **Waybar personalizada** con módulos útiles
- 🚀 **Rofi launcher** con múltiples menús
- 🔔 **Dunst** para notificaciones elegantes
- 🖥️ **Kitty terminal** con configuración optimizada

## 📦 Componentes incluidos

### Core
- **Hyprland** - Compositor Wayland
- **Waybar** - Barra de estado moderna
- **Rofi** - Launcher de aplicaciones
- **Dunst** - Sistema de notificaciones
- **Kitty** - Emulador de terminal

### VPN
- **OpenVPN** - Cliente VPN estándar
- **WireGuard** - VPN moderna y rápida
- **NetworkManager VPN** - Integración con NM
- **Scripts personalizados** - Gestión fácil de VPN

### Gaming
- **Steam** - Plataforma de juegos
- **Lutris** - Gestor de juegos
- **GameMode** - Optimizaciones de rendimiento
- **MangoHud** - Overlay de rendimiento

### Desarrollo
- **VS Code** - Editor de código
- **Git** - Control de versiones
- **Fish shell** - Shell moderna
- **Starship** - Prompt personalizable

## 🛠️ Instalación

### Instalación automática (recomendada)

```bash
git clone https://github.com/tu-usuario/hyprland-dotfiles.git
cd hyprland-dotfiles
chmod +x install.sh
./install.sh
```

### Instalación manual

1. **Clonar el repositorio:**
```bash
git clone https://github.com/tu-usuario/hyprland-dotfiles.git
cd hyprland-dotfiles
```

2. **Instalar dependencias:**
```bash
sudo pacman -S hyprland waybar rofi dunst kitty fish starship
```

3. **Copiar configuraciones:**
```bash
cp -r hypr waybar rofi dunst kitty fish ~/.config/
cp starship.toml ~/.config/
cp -r scripts/* ~/.local/bin/
```

## ⌨️ Atajos de teclado principales

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Terminal |
| `Super + D` | Launcher |
| `Super + Q` | Cerrar ventana |
| `Super + V` | Menú VPN |
| `Super + Shift + V` | Toggle VPN rápido |
| `Super + I` | Información del sistema |
| `Super + Shift + S` | Captura de pantalla |
| `Super + L` | Bloquear pantalla |

Ver [KEYBINDINGS.md](docs/KEYBINDINGS.md) para la lista completa.

## 🔒 Configuración VPN

### Configuración rápida
```bash
# Configurar VPN por defecto
Super + Ctrl + V

# Toggle VPN
Super + Shift + V

# Menú VPN completo
Super + V
```

Ver [VPN-SETUP.md](docs/VPN-SETUP.md) para configuración detallada.

## 🎨 Personalización

- **Temas:** Usa `nwg-look` para cambiar temas GTK
- **Wallpapers:** Coloca imágenes en `~/.config/hypr/wallpapers/`
- **Waybar:** Edita `~/.config/waybar/config.jsonc`
- **Colores:** Modifica los archivos de tema en cada aplicación

Ver [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) para más detalles.

## 🐛 Solución de problemas

### Problemas comunes

**Waybar no aparece:**
```bash
pkill waybar && waybar &
```

**VPN no conecta:**
```bash
sudo systemctl restart NetworkManager
```

**Audio no funciona:**
```bash
systemctl --user restart pipewire pipewire-pulse
```

Ver [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) para más soluciones.

## 📸 Screenshots

| Componente | Screenshot |
|------------|------------|
| Desktop | ![Desktop](screenshots/desktop.png) |
| Waybar | ![Waybar](screenshots/waybar.png) |
| Rofi | ![Rofi](screenshots/rofi.png) |
| VPN Menu | ![VPN](screenshots/vpn-menu.png) |

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Agradecimientos

- [Hyprland](https://hyprland.org/) - Por el increíble compositor
- [Catppuccin](https://catppuccin.com/) - Por los hermosos temas
- [Waybar](https://github.com/Alexays/Waybar) - Por la barra de estado
- La comunidad de Arch Linux y r/unixporn

## 📞 Soporte

- 🐛 [Issues](https://github.com/tu-usuario/hyprland-dotfiles/issues)
- 💬 [Discussions](https://github.com/tu-usuario/hyprland-dotfiles/discussions)
- 📧 Email: tu-email@ejemplo.com

---

⭐ Si te gusta este proyecto, ¡dale una estrella!
```

## 🚀 Comandos para subir a GitHub:

```bash
# Inicializar repositorio
git init
git add .
git commit -m "Initial commit: Complete Hyprland dotfiles with VPN support"

# Conectar con GitHub
git branch -M main
git remote add origin https://github.com/tu-usuario/hyprland-dotfiles.git
git push -u origin main
```

## 📥 Instalación desde GitHub:

```bash
# Clonar e instalar
git clone https://github.com/tu-usuario/hyprland-dotfiles.git
cd hyprland-dotfiles
chmod +x install.sh
./install.sh
