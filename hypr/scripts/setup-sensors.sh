#!/usr/bin/env bash
# Enables the AMD Sensor Fusion Hub accelerometer so the laptop can auto-rotate.
# Run with:  sudo bash /home/timo/.config/hypr/scripts/setup-sensors.sh
# Safe to re-run.
set -euo pipefail

MODPROBE_CONF="/etc/modprobe.d/amd-sfh.conf"
UNIT="/etc/systemd/system/amd-sfh-reload.service"

echo "==> 1/4 writing $MODPROBE_CONF"
install -Dm644 /dev/stdin "$MODPROBE_CONF" <<'EOF'
# HP ENVY x360 15-ee0xxx: AMD SFH discovery reports "sensors not enabled is 0",
# so no accelerometer is exposed. Force the accel+magno sensor mask, matching the
# upstream DMI overrides for other Envy x360 models in amd_sfh_pcie.c
# (ACEL_EN | MAGNO_EN => 1 | 4 = 5).
options amd_sfh sensor_mask=5
EOF
cat "$MODPROBE_CONF"

echo "==> 2/4 writing $UNIT"
install -Dm644 /dev/stdin "$UNIT" <<'EOF'
[Unit]
Description=Reload AMD Sensor Fusion Hub (amd_sfh) to probe the accelerometer
Documentation=https://bbs.archlinux.org/viewtopic.php?id=286254
After=systemd-modules-load.service multi-user.target
Wants=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/bash -c '/usr/bin/modprobe -r amd_sfh || true'
ExecStart=/usr/bin/modprobe amd_sfh

[Install]
WantedBy=multi-user.target
EOF
cat "$UNIT"

echo "==> 3/4 enabling the reload service"
systemctl daemon-reload
systemctl enable --now amd-sfh-reload.service

echo "==> 4/4 waiting for the sensor..."
sleep 4
if [ -z "$(ls -A /sys/bus/iio/devices/ 2>/dev/null)" ]; then
    echo "No IIO devices yet. Recent kernel messages:"
    journalctl -k --no-pager -n 40 2>/dev/null | grep -iE "sfh|mp2|sensor|iio" || true
else
    echo "IIO devices found:"
    for d in /sys/bus/iio/devices/iio:device*; do
        [ -e "$d" ] || continue
        printf '  %-40s name=%s\n' "$(basename "$d")" "$(cat "$d/name" 2>/dev/null)"
        udevadm info -q property -p "$d" 2>/dev/null | grep -E "IIO_SENSOR_PROXY_TYPE|ID_INPUT_ACCEL" || true
    done
fi