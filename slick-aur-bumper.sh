#!/usr/bin/env bash
PACKAGES=(slick-mod slick-mod-bundled)
CURRENTLY_INSTALLED_SLACK_ELECTRON=($(strings /usr/lib/slack/slack | grep -m 5 -E 'Electron/[0-9]+.[0-9]+.[0-9]+' --only-matching | head -1))
CURRENTLY_INSTALLED_SLACK_VERSION=($(pacman -Q slack-desktop | grep -E '[0-9]+.[0-9]+.[0-9]+-[0-9]*' --only-matching))
LATEST_SLACK_AUR_VERSION=($(curl -s https://aur.archlinux.org/rpc/v5/info\?arg\[\]\=slack-desktop | jq '.results[].Version' | tr -d "\""))
SLACK_AUR_FRESHNESS=($(vercmp $CURRENTLY_INSTALLED_SLACK_VERSION $LATEST_SLACK_AUR_VERSION))
echo "CURRENTLY_INSTALLED_SLACK_VERSION $CURRENTLY_INSTALLED_SLACK_VERSION LATEST_SLACK_AUR_VERSION $LATEST_SLACK_AUR_VERSION"
if [[ "$SLACK_AUR_FRESHNESS" -eq 0 ]]; then
    SLACK_AUR_FRESHNESS_STRING="Up-to-date"
elif [[ "$SLACK_AUR_FRESHNESS" -eq -1 ]]; then
    SLACK_AUR_FRESHNESS_STRING="Local is out of date"
elif [[ "$SLACK_AUR_FRESHNESS" -eq 1 ]]; then
    SLACK_AUR_FRESHNESS_STRING="Local more recent than AUR"
fi

echo "[*] Currently installed slack-desktop package: $CURRENTLY_INSTALLED_SLACK_VERSION"
echo "[*] Latest AUR slack-desktop version: $LATEST_SLACK_AUR_VERSION ($SLACK_AUR_FRESHNESS_STRING)"
echo "[*] Currently Installed Slack Electron: $CURRENTLY_INSTALLED_SLACK_ELECTRON"