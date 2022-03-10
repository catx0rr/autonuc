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
	echo -e "$banner \n"
	echo -e "
	Author: Raw Etnerrot (catx0rr)
	Github: https://github.com/catx0rr/autonuc.git
	"
}

function show_selection 
{
	echo -e "Please select a task to execute:\n
[1] Fast Nuclei Scan (Noisy)
[2] Low Bandwidth Nuclei Scan (Progressive)
[3] Ping Sweep
[4] Port Scan
[5] Nuclei Scan (Staged)
[6] Domain Enumeration

[7] View Configuration
[8] Update Nuclei Templates
[9] Help Screen
[0] Exit
"
}

function show_main_menu
{
	show_banner
	show_selection

	read -p ">> " getopt

	case $getopt in
		7|[Cc][Oo][Nn][Ff][Ii][Gg])
			view_config_call
			show_main_menu
			;;
		3|[Pp][Ii][Nn][Gg][Ss][Ww][Ee][Ee][Pp])
			echo "starting pingsweep"
			;;
		8|[Uu][Pp][Dd][Aa][Tt][Ee])
			update_template_call
			;;
		9|[Hh][Ee][Ll][Pp])
			echo "showing help screen"
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

