#!/bin/bash

function show_banner 
{
	banner='
               __        _   ____  ________
  ____ ___  __/ /_____  / | / / / / / ____/
 / __ `/ / / / __/ __ \/  |/ / / / / /     
/ /_/ / /_/ / /_/ /_/ / /|  / /_/ / /___   
\__,_/\__,_/\__/\____/_/ |_/\____/\____/   
                                           '
	clear
	echo -e "${grn}$banner \n${end}"
	echo -e "
	${grn}Author:${end} ${ylw}Raw Etnerrot (catx0rr)${end}
	${grn}Github:${end} ${blu}https://github.com/catx0rr/autonuc.git${end}
	"
}

function show_selection 
{
	echo -e "${prp}[*]${end} Please select a task to execute:\n
[1] Fast Nuclei Scan (Noisy)
[2] Low Bandwidth Nuclei Scan (Progressive)
[3] Ping Sweep 
[4] Port Scan
[5] Domain Enumeration
[6] Nuclei Scan (Staged)

[7] View Configuration
[8] Update Nuclei Templates
[9] Clear Data
${red}[0]${end} Exit
"
}

function show_main_menu
{
	show_banner
	show_selection
	read -p ">> " getopt

	case $getopt in
		1|[Ff][Aa][Ss][Tt][Ss][Cc][Aa][Nn])
			high_radar_scan
			;;
		2|[Pp][Rr][Oo][Gg][Ss][Cc][Aa][Nn])
			low_radar_scan
			;;
		3|[Pp][Ii][Nn][Gg][Ss][Ww][Ee][Ee][Pp])
			sweep_target
			;;
		4|[Pp][Oo][Rr][Tt][Ss][Cc][Aa][Nn])
			scan_target
			;;
		5|[Dd][Ee][Nn][Uu][Mm][Ee][Rr][Aa][Tt][Ee])
			enumerate_domain
			;;
		6|[Nn][Uu][Cc][Ll][Ee][Ii][Ss][Cc][Aa][Nn])
			nuclei_staged_scan
			;;
		7|[Cc][Oo][Nn][Ff][Ii][Gg])
			view_config_call
			;;
		8|[Uu][Pp][Dd][Aa][Tt][Ee])
			update_template_call
			;;
		9|[Cc][Ll][Ee][Aa][Rr][Dd][Aa][Tt][Aa])
			clear_data
			;;
		0|[Ee][Xx][Ii][Tt]|[Xx]|[Qq][Uu][Ii][Tt]|[Qq])
			exit 0
			;;
		*)
			show_main_menu
			;;

	esac
}

show_main_menu

