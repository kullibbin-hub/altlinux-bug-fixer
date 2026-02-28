#!/bin/sh
echo -e  '\e[33m
Получение sudo
'
pkexec bash control sudowheel enabled

echo -e  '\e[33m
sudo получено, далее потребуется ввод пароля еще раз.
Обновление системы и установка доп пакетов
\e[0m'
sudo apt-get update
sudo apt-get install -y eepm
epm full-upgrade -y
echo -e  '\e[33m
Будут установлены из репозитория: flatseal, bleachbit, 
extension-manager, synaptic, epmgpi, eepm-play-gui, baobab, 
sushi, luckybackup, qdiskinfo, gearlever, android-tools, 
java-21-openjdk, grub-theme-dark, icon-theme-Papirus, 
icon-theme-Papirus-Dark, pipewire-jack. 
А также расширения gnome shell:
add to desktop, blur my shell, no overview at startup.
\e[0m'
sudo apt-get install -y flatseal bleachbit extension-manager synaptic-usermode epmgpi eepm-play-gui baobab sushi luckybackup qdiskinfo gearlever android-tools grub-theme-dark icon-theme-Papirus icon-theme-Papirus-Dark pipewire-jack gnome-shell-extension-add-to-desktop gnome-shell-extension-blur-my-shell gnome-shell-extension-no-overview-at-startup

echo -e  '\e[33m
Отключение индексатора дисков
\e[0m'
systemctl --user mask localsearch-3
systemctl --user stop localsearch-3
echo 'Служба localsearch-3 отключена
'
echo -e  '\e[33m
Отключение автообновления
\e[0m'
gsettings set org.gnome.software download-updates false
echo 'Автообновление отключено, это ускорило запуск центра
приложений, но уведомления об их наличии будут приходить все равно!
'
echo -e  '\e[33m
Разрешение приложениям Flatpak на доступ к домашнему каталогу
\e[0m'
flatpak override --user --filesystem=home
echo 'готово, теперь drag-n-drop с рабочего стола работает.
'
echo -e  '\e[33m
Настройка адекватного поведения индикатора копирования nautilus
\e[0m'
DIRTY_FILE="/etc/sysctl.d/90-dirty.conf"

echo "→ Applying and saving vm.dirty settings..."

# 32 МБ и 8 МБ
DIRTY_BYTES=$((64 * 1024 * 1024))
DIRTY_BG_BYTES=$((16 * 1024 * 1024))

echo "→ Writing persistent config to $DIRTY_FILE"
sudo bash -c "cat > $DIRTY_FILE" <<EOF
vm.dirty_bytes = $DIRTY_BYTES
vm.dirty_background_bytes = $DIRTY_BG_BYTES
EOF

echo "→ Applying values now..."
sudo sysctl -p "$DIRTY_FILE"

echo "✓ Done. Persistent settings active!"
echo "
Check after reboot:"
echo " sudo sysctl vm.dirty_bytes vm.dirty_background_bytes

Готово.
"

echo -e  '\e[33m
Фикс ложного включения gsconnect
\e[0m'
AUTOSTART_DIR="$HOME/.config/autostart"
SCRIPT_DIR="$HOME/.local/bin"

SCRIPT_FILE="$SCRIPT_DIR/kill-daemonjs.sh"
DESKTOP_FILE="$AUTOSTART_DIR/kill-daemonjs.desktop"

mkdir -p "$SCRIPT_DIR"
mkdir -p "$AUTOSTART_DIR"

cat > "$SCRIPT_FILE" << 'EOF'
#!/bin/sh
sleep 8
killall daemon.js
EOF

chmod +x "$SCRIPT_FILE"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Kill daemon.js
Exec=$SCRIPT_FILE
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

echo "Автозагрузка создана: $DESKTOP_FILE
Теперь gsconnect работает адекватно
"

echo -e  '\e[33m
Настройка nautilus
\e[0m'
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.preferences show-delete-permanently true
gsettings set org.gnome.nautilus.icon-view captions "['size', 'date_modified', 'none']"
echo 'Включены опции: папки перед файлами, создание ссылок,
удаление помимо корзины, и доп. информация о файлах в режиме значков.
'
echo -e  '\e[33m
Фикс появления фантомных устройств в индикаторе флешек
\e[0m'
RULES_DIR="/etc/polkit-1/rules.d"
RULE_FILE="$RULES_DIR/49-no-usb-mount-gdm.rules"

# Создаём каталог, если его нет
if [ ! -d "$RULES_DIR" ]; then
    echo "Создаю каталог $RULES_DIR ..."
    sudo mkdir -p "$RULES_DIR"
fi

# Создаём файл с правилом
echo "Создаю polkit-правило для запрета монтирования USB в GDM..."

sudo bash -c "cat > $RULE_FILE" << 'EOF'
polkit.addRule(function(action, subject) {
    if (subject.user == "gdm") {
        if (action.id == "org.freedesktop.udisks2.filesystem-mount" ||
            action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
            action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
            action.id == "org.freedesktop.udisks2.encrypted-unlock-other-seat" ||
            action.id == "org.freedesktop.udisks2.loop-setup") {
            return polkit.Result.NO;
        }
    }
});
EOF

# Выставляем права
echo "Устанавливаю права 644 на $RULE_FILE ..."
sudo chmod 644 "$RULE_FILE"

echo -e  "\e[33m
Готово. Теперь желательно перезагрузить компьютер.
\e[0m"


