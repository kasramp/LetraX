# This file is part of Letrax
# Pulsey is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3
# as published by the Free Software Foundation.
#
# Pulsey is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.  <http://www.gnu.org/licenses/>
#
# Author(s):
# © 2018 Kasra Madadipouya <kasra@madadipouya.com>

#!/bin/bash

function main() {
	letrax
}

function letrax() {
	back_title="LetraX -- Ncurses interface for AZLyrics.com"
	search_query=$(dialog --keep-tite --backtitle "$back_title" --nocancel --output-fd 1 --inputbox "Search for a song or artist:" 8 70 | sed -e "s/ /+/g")
	query_results=$(curl -s "https://search.azlyrics.com/search.php?q=$search_query" | hxnormalize -x | hxselect 'table.table.table-condensed tbody tr td.text-left.visitedlyr' | hxselect 'td')
	IFS=$'\n'
	links=($(echo $query_results | grep -Po '(?<=href=")[^"]*'))
	songs_artists=($(echo $query_results | grep -oE '<b>[^<]*</b>' | sed 's/<b>//g' | sed 's/<\/b>//g'))
	
	options=()
	j=-1
	for ((i = 0; i < ${#links[@]}; ++i)); do
		j=$(( $j + 1 ))
		song=$(echo "${songs_artists[$j]}" | tr -s " ")
		j=$(( $j + 1 ))
		artist=$(echo ${songs_artists[$j]} | tr -s " ")
		song_artist="$song, $artist"
		options+=($(( $i + 1 )))
		options+=($song_artist)
	done

	song_index=$(dialog --keep-tite --backtitle $back_title --title "Search Result" --scrollbar --cancel-label "Back" --menu --output-fd 1 "Select a lyrics:" 30 100 30 ${options[*]})

	keypressed=$?
	if [ $keypressed -eq 255 ]
		then
		quit
	elif [ $keypressed -eq 1 ]
		then
		letrax
	elif [ $keypressed -eq 0 ]
		then
		song_index=$(( $song_index - 1 ))
		result=$(curl -s "${links[$song_index]}" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-GB,en;q=0.5' --compressed -H 'Cookie: __utma=190584827.2035041728.1477103053.1480301796.1534063828.4; __atuvc=1%7C44%2C0%7C45%2C0%7C46%2C0%7C47%2C1%7C48; __atssc=google%3B3; __utmz=190584827.1534063828.4.1.utmcsr=azlyrics.com|utmccn=(referral)|utmcmd=referral|utmcct=/; __utmc=190584827' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0' | hxnormalize -x | hxselect "div.col-xs-12:nth-child(2) > div:nth-child(8)")
		lyrics=$(echo $result | sed 's/<div>//g' | sed 's/<\/div>//g' | sed 's/<br\/>/\n/g' | tr -s " ")
		title_index=$(( $song_index * 2 + 1 ))
		dialog --keep-tite --backtitle $back_title --title ${options[$title_index]} --scrollbar --msgbox "$lyrics" 35 100
		
		keypressed=$?
		if [ $keypressed -eq 255 ]
			then
			quit
		elif [ $keypressed -eq 0 ]
			then
			letrax
		fi
	fi
	unset IFS
}

function quit() {
	#reset
	exit 0
}

main "$@"
