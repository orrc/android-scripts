# Shows connected Android devices and emulators, and their type,
# allows one to be selected, whose serial number will be returned
#
# Parameters:
# - initial query text (optional)
#
# Requirements:
# - the current directory must be a git repository
#
# Assumptions:
# - the primary remote is called "origin"
#
# Prerequisites:
# - `adb` is available on the `PATH`
# - `perl` is installed
#
# Compatibility:
# - Only tested on macOS
# - The `tail` syntax might not be portable
device() {
  # Attempt to start the ADB server up-front; otherwise we would see various
  # "starting server" text appear on stdout, which would get passed to fzf
  adb start-server &> /dev/null || { echo >&2 'Error: adb not found on $PATH' && return 1; }

  # Show connected Android devices; remove the header line; remove excess
  # whitespace; transform output to include serial and device info; print as
  # two columns with ANSI colouring; pass to fzf, return immediately if there
  # are no devices connected, or exactly one device; return the selected serial
  echo $(adb devices -l | tail -n +2 | sed '/^\s*$/d' \
         | perl -pe 's/([^ ]+).*?model:([^ :\v]+).*/\1 \2/g' \
         | awk '{printf "\x1b[36m%-24s\x1b[m%s\n",$1,$2}' \
         | fzf --ansi --multi -0 -1 --header="Choose a device" -q "$1" \
         | awk '{print $1}')
}

# Shows the list of APKs installed on a certain Android device, allows one to be
# selected; that file will be pulled from the device and renamed appropriately
#
# Parameters:
# - device query text (optional)
# - initial application ID query text (optional)
#
# Prerequisites:
# - `adb` is available on the `PATH`
# - `aapt` is available on the `PATH`
#
# Compatibility:
# - Only tested on macOS
# - The `sed` syntax may not be POSIX compliant
apk() {
  local query serial path tmpfile app_id version final_name

  # Check whether aapt is available
  aapt version > /dev/null || { echo >&2 'Error: aapt not found on $PATH' && return 1; }

  # If there are multiple parameters, assume the first one is a device query
  if [ $# -gt 1 ]; then
    query=$1
    shift
  fi

  # Get the serial of a device
  serial=$(device $query)
  if [ -z "$serial" ]; then echo 'No device selected'; return 1; fi

  # Fetch the list of installed APKs; remove the "package:" prefix; swap the
  # path and application ID parts, removing the "=" separator; sort the list
  # by application ID; print as two columns with ANSI colouring; pass to fzf,
  # return immediately if there are zero (or one) APK(s) available; return the
  # path on the device of the selected APK
  path=$(adb -s $serial shell pm list packages -f \
             | cut -d: -f2- | sed -E 's/(.*)=(.*)/\2 \1/' | sort \
             | awk '{printf "\x1b[36m%-48s\x1b[m%s\n",$1,$2}' \
             | fzf --ansi -0 -1 -n1 --header="Choose an APK from $serial" -q "$*" \
             | awk '{print $2}')
  if [ -z "$path" ]; then echo 'No APK selected'; return 1; fi

  # Pull the APK to a temporary file
  tmpfile="$TMPDIR/pull_$RANDOM.apk"
  adb -s $serial pull "$path" "$tmpfile"

  # Extract the APK's metadata
  app_id=$(aapt dump badging "$tmpfile" | head -n1 | sed -E "s/.*name='([^']+)'.*/\1/")
  version=$(aapt dump badging "$tmpfile" | head -n1 | sed -E "s/.*versionCode='([0-9]+)'.*/\1/")

  # Rename the APK with its properties
  final_name="${app_id}_${version}.apk"
  mv "$tmpfile" "$final_name"
  echo "Saved APK from $serial to $final_name"
}

# Shows the list of APKs found a directory, allows one or more of them to be
# selected, shows the list of connected Android devices and emulators, allows
# one or more of them to be selected, then installs the APK(s) on the devices(s)
#
# Parameters:
# - directory to search for APKs in (optional; falls back to current directory)
#
# Prerequisites:
# - `adb` is available on the `PATH`
# - `aapt` is available on the `PATH`
#
# Bugs:
# - Likely fails if an APK filename includes spaces
#
# Compatibility:
# - Only tested on macOS
# - `find` syntax may not be portable
install() {
  local apks devices

  # Locate *.apk files in the given directory; pass to fzf, showing basic
  # information about the APK in a preview window; return immediately if there
  # are zero (or one) APK(s) found; return the path to the selected APK(s)
  apks=$(find -L ${1:-.} -name '*.apk' \
         | fzf --multi -0 -1 \
           --preview-window=up:5 \
           --preview 'aapt dump badging {} \
             | egrep "versionCode|launchable-|native-code"')
  if [ -z "$apks" ]; then echo 'No APK(s) selected'; return 1; fi

  # Select the device(s) to install onto
  devices=$(device)
  if [ -z "$devices" ]; then echo 'No device(s) selected'; return 1; fi

  # Install the APK(s) onto each device
  for serial in $devices; do
    for apk in $apks; do
      echo "Installing $apk onto $serial"
      adb -s $serial install -r "$apk"
      echo
    done
  done
}
