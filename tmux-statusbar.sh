#/bin/bash

# zlib License
# 
# (C) 2019 Daniel Meszaros <easimer@gmail.com>
# 
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
# 
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
# 
# 1. The origin of this software must not be misrepresented; you must not
# claim that you wrote the original software. If you use this software
# in a product, an acknowledgment in the product documentation would be
# appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not
# be
# misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source
# distribution.

battery() {
	battery_status=""
	ac_status="$(acpi -a | cut -d ':' -f 2)"
	battery_level="$(acpi | cut -d ',' -f 2)"

	if [ $ac_status = "on-line" ]; then
		battery_status=" AC${battery_level}"
	else
		battery_status="BAT${battery_level}"
	fi

	printf "%s" "$battery_status"
}

network() {
	WIRED="$(ethtool eth0)"
	WIRELESS="$(ethtool pciwlan0)"

	WIRED_LINK=`echo "$WIRED" | grep "Link detected" | cut -d ':' -f 2`
	if [ "$WIRED_LINK" = " yes" ]; then
		WIRED_SPEED=`echo "$WIRED" | grep "Speed" | cut -d ':' -f 2`
		printf " Eth%s " "$WIRED_SPEED"
		return
	fi

	WIRELESS_LINK=`echo "$WIRELESS" | grep "Link detected" | cut -d ':' -f 2`
	if [ "$WIRELESS_LINK" = " yes" ]; then
		SSID=`iw dev pciwlan0 link | grep "SSID" | cut -d ':' -f 2`
		printf "%s " "$SSID"
		return
	fi
	printf "Offline"
}

music_rhythmbox() {
	MUSIC_STATUS=`gdbus call --session --dest org.mpris.MediaPlayer2.rhythmbox --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2.Player PlaybackStatus`
	if [ "$MUSIC_STATUS" = "(<'Playing'>,)" ]; then
		TRACK_TITLE=`rhythmbox-client --print-playing | awk -v len=35 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }'`
		printf " ♫ %s |"  "$TRACK_TITLE"
        exit 0
    else
        exit 1
	fi
}

music_mpv() {
    if [[ -e ~/.mpv.socket ]]; then
        TRACK_TITLE=$(echo '{ "command": ["get_property", "metadata"] }' | socat - ~/.mpv.socket | jq '.data."icy-title"')
        printf " ♫ %s |" "$TRACK_TITLE"
        exit 0
    else
        exit 1
    fi
}

music() {
    if [[ ! music_rhythmbox ]]; then
        exit 0
    else
        music_mpv
    fi
}

neptun() {
    NEPTUN_LINE=`~/.local/bin/neptun_next -s`
    if [ ! -z "$NEPTUN_LINE" ]; then
        printf "$NEPTUN_LINE |"
    fi
}

main() {
    #printf "%s |" "$(battery)"
    #printf "%s|" "$(network)"
    #printf "%s" "$(music)"
    #printf "%s" "$(neptun)"

    #printf " %s\n" "$(date +'%D %l:%M%p')"

    printf "%s |%s|%s%s %s\n" "$(battery)" "$(network)" "$(music)" "$(neptun)" \
    "$(date +'%D %l:%M%p')"
}

if [[ "$1" == "i3" ]]; then
    i3status | while :
    do
        read line
        main 2>/dev/null || exit 1
    done
else
    main
fi
