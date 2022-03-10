#!/bin/bash

## [7] View Config

function show_config
{
	less $path/config/autonuc.conf
}

## [8] Update Nuclei Templates / Nuclei Templates

function show_templates_count
{
	if [[ $(ls -l $path/_nuclei/nuclei-templates/all | wc -l) -eq 1 ]]; then
		echo -e "[*] Available Templates: 0"
	else
		echo -e "[*] Available Templates: $(ls -l $path/_nuclei/nuclei-templates/all/ | wc -l)"
	fi
}

function update_template
{
	echo -ne "[?] Do you want to fetch new templates from github? [y/N] >> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			echo -e "[*] Updating nuclei templates from github.."
			
			if [[ $(curl -sI https://github.com/projectdiscovery/nuclei-templates | head -n1 | cut -d' ' -f2) == "200" ]]; then
				rm -rf $path/_nuclei/nuclei-templates 2>/dev/null && echo
				git clone https://github.com/projectdiscovery/nuclei-templates $path/_nuclei/nuclei-templates && echo
				mkdir -p $path/_nuclei/nuclei-templates/all 2>/dev/null
				find $path/_nuclei/nuclei-templates -type f -name *.yaml | xargs -I % cp % $path/_nuclei/nuclei-templates/all 2>/dev/null
			else
				echo -e "[-] Update failed. Please check internet connection :("
				sleep 6 && show_main_menu
			fi
			
			echo -e "[+] Update Succeeded."
			show_templates_count
			sleep 6 && show_main_menu
			;;
		[Nn]|[Nn][Oo])
			show_main_menu
			;;
		*)
			clear
			show_banner
			show_templates_count
			update_template
			;;
	esac
}	
