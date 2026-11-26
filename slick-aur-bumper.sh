#!/usr/bin/env bash
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


PACKAGES=(slick-mod slick-mod-bundled)
CURRENTLY_INSTALLED_SLACK_ELECTRON=($(strings /usr/lib/slack/slack | grep -m 5 -E 'Electron/[0-9]+.[0-9]+.[0-9]+' --only-matching | head -1))
CURRENTLY_INSTALLED_SLACK_VERSION=($(pacman -Q slack-desktop | grep -E '[0-9]+.[0-9]+.[0-9]+-[0-9]*' --only-matching))
LATEST_SLACK_AUR_VERSION=($(curl -s https://aur.archlinux.org/rpc/v5/info\?arg\[\]\=slack-desktop | jq '.results[].Version' | tr -d "\""))
SLACK_AUR_FRESHNESS=($(vercmp $CURRENTLY_INSTALLED_SLACK_VERSION $LATEST_SLACK_AUR_VERSION))
NEED_TO_UPDATE_ELECTRON=0

if [[ ! $(command -v gum) ]]; then
    echo -e "${RED}[*] Dependency missing: gum${ENDCOLOR}"
    exit 1
fi

if [[ "$SLACK_AUR_FRESHNESS" -eq 0 ]]; then
    SLACK_AUR_FRESHNESS_STRING="${GREEN}Up-to-date${ENDCOLOR}"
elif [[ "$SLACK_AUR_FRESHNESS" -eq -1 ]]; then
    SLACK_AUR_FRESHNESS_STRING="${RED}Local is out of date${ENDCOLOR}"
elif [[ "$SLACK_AUR_FRESHNESS" -eq 1 ]]; then
    SLACK_AUR_FRESHNESS_STRING="${BLUE}Local more recent than AUR${ENDCOLOR}"
fi

echo -e "[*] Currently installed slack-desktop package: $CURRENTLY_INSTALLED_SLACK_VERSION ($SLACK_AUR_FRESHNESS_STRING)"
if [[ "$SLACK_AUR_FRESHNESS" -eq -1 || "$SLACK_AUR_FRESHNESS" -eq 1 ]]; then
    echo -e "[*] - Latest AUR slack-desktop version: $LATEST_SLACK_AUR_VERSION"
fi
echo -e "[*] Currently Installed Slack Electron: $CURRENTLY_INSTALLED_SLACK_ELECTRON"

if [[ "$SLACK_AUR_FRESHNESS" -eq -1 || "$SLACK_AUR_FRESHNESS" -eq 1 ]]; then
    rm -rf /tmp/slack-desktop-electron-check
    gum spin --title "Git cloning slack-desktop" -- git clone https://aur.archlinux.org/slack-desktop.git /tmp/slack-desktop-electron-check
    cd /tmp/slack-desktop-electron-check
    gum spin --title "Running makepkg on slack-desktop (to get Electron version)" -- sh -c 'BUILDDIR="$PWD/build" PKGDEST="$PWD" makepkg'
    SLACK_AUR_ELECTRON=($(strings $PWD/build/slack-desktop/pkg/slack-desktop/usr/lib/slack/slack | grep -m 5 -E 'Electron/[0-9]+.[0-9]+.[0-9]+' --only-matching | head -1))
    echo -e "[*] - Slack AUR's Electron Version: $SLACK_AUR_ELECTRON"
fi
slick_mod_electron_version=($(curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=slick-mod" | grep -m 5 -E '_electron=electron[0-9]+.' |  grep -m 5 -E '[0-9]+.' --only-matching ))
CURRENTLY_INSTALLED_SLACK_ELECTRON_SHORT=($(echo $CURRENTLY_INSTALLED_SLACK_ELECTRON | grep -m 5 -E '[0-9]+' --only-matching | head -n 1))
if [[ -v "$SLACK_AUR_ELECTRON" ]]; then
    SLACK_AUR_ELECTRON_SHORT=($(echo $SLACK_AUR_ELECTRON | grep -m 5 -E '[0-9]+' --only-matching | head -n 1))
fi
if [[ ( -v "$SLACK_AUR_ELECTRON_SHORT" && "$SLACK_AUR_ELECTRON_SHORT" -gt "$slick_mod_electron_version") || "$CURRENTLY_INSTALLED_SLACK_ELECTRON_SHORT" -gt "$slick_mod_electron_version" ]]; then
    NEED_TO_UPDATE_ELECTRON=1
fi
echo "Need to Update Electron? $NEED_TO_UPDATE_ELECTRON"
for package in slick-mod slick-mod-bundled
    do
        echo "[*] Starting $package update..."
        if [[ ! -d /home/$USER/Projects/Git/$package ]]; then
            echo "[*] /home/$USER/Projects/Git/$package does not exist, creating it..."
            mkdir -p /home/$USER/Projects/Git/$package
        fi
done