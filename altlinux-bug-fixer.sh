#!/bin/sh

echo -e  '\e[33m
Получение sudo
\e[0m'

pkexec bash control sudowheel enabled

echo '
sudo получено.
'

#=============================================================

echo -e  '\e[33m
Обновление системы и установка доп пакетов.
Потребуется ввод пароля еще раз (символы не отображаются):

\e[0m'

sudo apt-get update
sudo apt-get dist-upgrade -y

echo '
Система обновлена.
'

#============================================================

echo -e  '\e[33m
Добавление текущего пользователя в группу dialout
\e[0m'

sudo usermod -a -G dialout $USER
 
echo '
Готово. 
'

#=============================================================

echo -e  '\e[33m
Установка из репозитория: flatseal, tuner с плагинами,
gnome-extension-manager, synaptic, epmgpi, eepm-play-gui,
baobab, sushi, qdiskinfo, gearlever, android-tools, spruce, 
pins, java-21-openjdk, grub-theme-dark, pipewire-jack, 
nautilus-admin-gtk4, eepm, showtime, gapless, git, simple-scan,
foldy (менеджер папок полноэкранного меню Gnome), resources,
ffmpeg, hplip.
А также расширения gnome shell:
add to desktop, blur my shell, no overview at startup,
appindicator.
\e[0m'

# Далее установка доп. программ. Ненужные можно удалить, сохраняя пробел между соседними записями.

sudo apt-get install -y eepm flatseal gnome-extension-manager synaptic-usermode ignition-adw epmgpi eepm-play-gui baobab sushi  qdiskinfo gearlever android-tools grub-theme-dark pipewire-jack gnome-shell-extension-add-to-desktop gnome-shell-extension-blur-my-shell gnome-shell-extension-no-overview-at-startup patch pip python3-module-pip spruce pins file unzip shared-mime-info nautilus-admin-gtk4 showtime g4music gnome-shell-extension-appindicator git foldy simple-scan resources ffmpeg hplip-gui hplip-sane tuner ^tuner-*

sudo epm upgrade "https://download.etersoft.ru/pub/Korinf/x86_64/ALTLinux/p11/eepm-*.noarch.rpm"
sudo epm play --update all

echo '
Готово, программы установлены. 
'

#==========================================================

#echo -e  '\e[33m
#Отключение индексатора содержимого файлов
#\e[0m'
#systemctl --user mask localsearch-3
#systemctl --user stop localsearch-3
#echo 'Служба localsearch-3 отключена
#'
systemctl --user unmask localsearch-3

#==========================================================

echo -e  '\e[33m
Отключение автообновления
\e[0m'
gsettings set org.gnome.software download-updates false
echo 'Автообновление отключено, это ускорило запуск центра
приложений, но уведомления об их наличии будут приходить все равно!
'

#==========================================================

echo -e  '\e[33m
Разрешение приложениям Flatpak на доступ к домашнему каталогу
\e[0m'
flatpak override --user --filesystem=home
echo 'готово, теперь drag-n-drop с рабочего стола работает.
'

#==========================================================

echo -e  '\e[33m
Настройка адекватного поведения индикатора копирования nautilus
\e[0m'
DIRTY_FILE="/etc/sysctl.d/90-dirty.conf"

echo "→ Applying and saving vm.dirty settings..."

# 64 МБ и 16 МБ
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

#==========================================================

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
sleep 10
pkill -f "/usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/service/daemon.js"
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

#==========================================================

echo -e  '\e[33m
Настройка nautilus
\e[0m'

gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.preferences show-delete-permanently true
gsettings set org.gnome.nautilus.icon-view captions "['size', 'date_modified', 'none']"

echo 'Включены опции: папки перед файлами, создание ссылок,
удаление помимо корзины, и доп. информация о файлах в режиме значков.
Добавление опции - открыть от имени администратора (nautilus-admin)
'
echo '
Готово.'

#==========================================================

echo -e  '\e[33m
Фикс появления фантомных устройств в индикаторе флешек
\e[0m'

sudo rm -f /etc/polkit-1/rules.d/49-no-usb-mount-gdm.rules
set -e

EXT_DIR="/usr/share/gnome-shell/extensions"
EXT_NAME="drive-menu@gnome-shell-extensions.gcampax.github.com"
FILE="extension.js"
TARGET="$EXT_DIR/$EXT_NAME/$FILE"
BACKUP="$TARGET.bak"

# Оригинальный размер файла, который можно патчить
ORIGINAL_SIZE=6197

echo "Проверяю наличие системного расширения..."

if [ ! -f "$TARGET" ]; then
    echo "Ошибка: файл $TARGET не найден."
    exit 1
fi

CURRENT_SIZE=$(stat -c%s "$TARGET")

echo "Оригинальный размер: $ORIGINAL_SIZE"
echo "Текущий размер:      $CURRENT_SIZE"

# Проверка размера
if [ "$CURRENT_SIZE" != "$ORIGINAL_SIZE" ]; then
    echo "Размер файла изменился. Патч НЕ применяется."
    :
else
    # Проверка, что патч ещё не применён
    if grep -q "this._mounts.some" "$TARGET"; then
        echo "Патч уже применён. Ничего делать не нужно."
        echo "Продолжаю выполнение скрипта."
        :
    else
        echo "Размер совпадает. Файл оригинальный. Создаю резервную копию: $BACKUP"
        sudo cp "$TARGET" "$BACKUP"

        echo "Применяю патч..."

        sudo patch "$TARGET" << 'EOF'
@@ -178,6 +178,9 @@
     }
 
     _addMount(mount) {
+        if (this._mounts.some(item => item.mount === mount))
+            return;
+
         let item = new MountMenuItem(mount);
         this._mounts.unshift(item);
         this.menu.addMenuItem(item, 0);
EOF

        echo "Патч успешно применён."
        echo "Очищаю кэш GNOME Shell..."
        rm -rf ~/.cache/gnome-shell/*
    fi
fi

echo '
Готово.'

#==========================================================

echo -e  '\e[33m
Добавление в контекстное меню нижней панели доп. программ
\e[0m'

gsettings set org.gnome.shell.extensions.dash-to-panel context-menu-entries '[{"title":"Terminal","cmd":"kgx"},{"title":"System monitor","cmd":"resources"},{"title":"Files","cmd":"nautilus"},{"title":"Extensions","cmd":"extension-manager"},{"title":"Тюнер","cmd":"tuner"},{"title":"Очистка кэша приложений","cmd":"spruce"},{"title":"Альтератор - центр управления","cmd":"acc"}]'
gsettings set org.gnome.shell.extensions.dash-to-panel overview-click-to-exit true
gsettings set org.gnome.shell.extensions.dash-to-panel secondarymenu-contains-showdetails true
gsettings set org.gnome.shell.extensions.arcmenu menu-height 600

echo 'Теперь меню имеет вид:

Терминал
Системный монитор
Файлы
Расширения
Тюнер
Очистка кэша приложений
Альтератор - центр управления
'

echo '
Готово.'

#===========================================================

echo -e  '\e[33m
Создание thumbnailer для .FCstd файлов.
\e[0m'

echo 'Удаление старых файлов'
sudo rm -f /usr/local/bin/fcstd-thumbnailer
sudo rm -f /usr/share/thumbnailers/fcstd.thumbnailer
echo '
Создание файла /usr/local/bin/freecad-thumbnailer'
sudo tee /usr/local/bin/freecad-thumbnailer > /dev/null << 'EOF'
#!/bin/bash

INPUT="$3"
OUTPUT="$4"

# проверка наличия thumbnail внутри архива
if unzip -l "$INPUT" thumbnails/Thumbnail.png >/dev/null 2>&1; then
    unzip -p "$INPUT" thumbnails/Thumbnail.png > "$OUTPUT"
    exit 0
else
    # важно: не создавать OUTPUT
    exit 1
fi
EOF

sudo chmod +x /usr/local/bin/freecad-thumbnailer

echo '
Создание файла /usr/share/thumbnailers/FreeCAD1.thumbnailer'
sudo tee /usr/share/thumbnailers/FreeCAD1.thumbnailer > /dev/null << 'EOF'
[Thumbnailer Entry]
TryExec=freecad-thumbnailer
Exec=freecad-thumbnailer -s %s %i %o
MimeType=application/x-extension-fcstd;
EOF

echo '
Готово.'

#===========================================================

echo -e  '\e[33m
Создание thumbnailer для .dwg файлов.
\e[0m'

set -e

# 1. Скачивание архива
echo 'Скачиваем NConvert
'
cd /tmp
wget https://download.xnview.com/NConvert-linux64.tgz -O NConvert-linux64.tgz

# 2. Распаковка в /usr/local
#sudo rm -rf /usr/local/NConvert
sudo tar -xzf NConvert-linux64.tgz -C /usr/local
#sudo mv /usr/local/NConvert-linux64 /usr/local/NConvert

# 3. Симлинк в /usr/local/bin
sudo rm -f /usr/local/bin/nconvert
sudo ln -s /usr/local/NConvert/nconvert /usr/local/bin/nconvert

# 4. Скрипт dwg-thumbnail.sh
echo 'Создаем /usr/local/bin/dwg-thumbnail.sh
'
sudo tee /usr/local/bin/dwg-thumbnail.sh >/dev/null <<'EOF'
#!/bin/bash
INPUT="$1"
OUTPUT="$2"
SIZE="$3"

NCONVERT="/usr/local/bin/nconvert"

# Создаём директорию для результата
mkdir -p "$(dirname "$OUTPUT")"

# Создаём временный файл с расширением .dwg
TMP="/tmp/dwgthumb-$$.dwg"
cp "$INPUT" "$TMP"

# Генерация PNG
"$NCONVERT" -quiet -out png -resize "$SIZE" "$SIZE" -o "$OUTPUT" "$TMP"

rm -f "$TMP"
EOF

sudo chmod +x /usr/local/bin/dwg-thumbnail.sh

# 5. Файл dwg.thumbnailer
echo 'Создаем /usr/share/thumbnailers/dwg.thumbnailer
'
sudo tee /usr/share/thumbnailers/dwg.thumbnailer >/dev/null <<'EOF'
[Thumbnailer Entry]
TryExec=/usr/local/bin/dwg-thumbnail.sh
Exec=/usr/local/bin/dwg-thumbnail.sh %i %o %s
MimeType=image/vnd.dwg; image/x-dwg; application/acad;
Flags=NoCopy
EOF

echo '
Готово.'

#===========================================================

echo -e  '\e[33m
Установка f3d через epm play
\e[0m'

sudo epm install -y task/409890/f3d

echo '
Готово.'

#===========================================================

echo '
Очистка кэша'

rm -rf ~/.cache/thumbnails/*

#===========================================================

echo -e  '\e[33m
Готово. 

Если установлена нижняя панель (расширение dash-to-panel), то 
по правому клику на панели доступны все настроечные приложения,
в том числе и Тюнер. В том же меню есть и настройка расширений.

Теперь желательно перезагрузить компьютер.
\e[0m'


