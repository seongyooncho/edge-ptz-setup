#!/bin/bash
set -euo pipefail

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d-%H%M%S)"

# Lines to add inside [cm5] section (exact matches will be deduplicated)
ADD_LINES=$'# BEGIN edge-ptz-setup\n'\
'dtoverlay=imx708,cam0\n'\
'dtoverlay=uart0\n'\
'dtoverlay=uart2\n'\
'dtparam=pciex1_gen=3\n'\
'# END edge-ptz-setup'

echo "[*] Backing up to $BACKUP_FILE"
sudo cp -a "$CONFIG_FILE" "$BACKUP_FILE"

# Process with awk:
#  - Inside [cm5], skip any line that matches one of ADD_LINES (deduplication)
#  - At the end of [cm5] section, insert the ADD_LINES block once
#  - If no [cm5] section exists, append it at the end of file
sudo awk -v adds="$ADD_LINES" '
BEGIN{
  n = split(adds, addarr, "\n")
  for (i=1;i<=n;i++) {
    if (length(addarr[i])) want[addarr[i]] = 1
  }
}
function print_adds() {
  for (i=1;i<=n;i++) print addarr[i]
}
{
  if ($0 ~ /^\[[^]]+\]$/) {
    if (in_cm5) {
      if (!added) { print_adds(); added=1 }
      in_cm5=0
    }
    if ($0 == "[cm5]") { in_cm5=1; seen_cm5=1; added=0 }
  }

  if (in_cm5) {
    if ($0 in want) next
  }

  print
}
END{
  if (in_cm5) {
    if (!added) { print_adds(); added=1 }
  } else if (!seen_cm5) {
    print ""
    print "[cm5]"
    print_adds()
  }
}
' "$BACKUP_FILE" | sudo tee "$CONFIG_FILE" >/dev/null

echo "[*] Done. Updated [cm5] section without duplicates."
echo "    Backup saved at: $BACKUP_FILE"
