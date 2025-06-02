function update
    switch $argv[1]
        case "system" ""
            echo "🔄 Actualizando sistema completo..."
            sudo pacman -Syu
            if command -v yay >/dev/null
                yay -Syu
            end
        case "aur"
            if command -v yay >/dev/null
                echo "🔄 Actualizando paquetes AUR..."
                yay -Syu --aur
            else
                echo "❌ yay no está instalado"
            end
        case "flatpak"
            if command -v flatpak >/dev/null
                echo "🔄 Actualizando Flatpak..."
                flatpak update
            else
                echo "❌ Flatpak no está instalado"
            end
        case "mirrors"
            echo "🔄 Actualizando mirrors..."
            sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        case "*"
            echo "Update Manager"
            echo "=============="
            echo "update system   - Actualizar sistema completo"
            echo "update aur      - Actualizar solo AUR"
            echo "update flatpak  - Actualizar Flatpak"
            echo "update mirrors  - Actualizar mirrors"
    end
end
