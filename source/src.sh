#!/bin/bash

function randelay
{
	sleep $((RANDOM % 3 + 1))
}

function pause_screen
{
	echo
	read -p ">> " getopt

	case getopt in
		*) show_main_menu
		;;
	esac
}

## [1] Fast Scan (Nuc Scan)

function fast_scan
{
	echo fastscan
}

## [2] Progressive Scan (Nuc Scan)

function progressive_scan
{
	echo progscan
}

## [3] Ping Sweep

function ping_sweep
{
	echo -e "${grn}[+]${end} Targets:\n
$(grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"')\n"
	echo -ne "${ylw}[>]${end} Do you want to start sweeping target networks? [y/N]>> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			randelay
			echo -e "${prp}[*]${end} Sweeping target networks.."

			for i in $(grep TARGETS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/TARGETS=//' | tr -d '"')
			do
				randelay
				echo -e "${grn}[+]${end} Start sweep on target $i..\n"

				timestart=$(date +%s.%N)
				for j in $(echo $i | sed -E 's/\.[0-9]{1,3}\/[0-9]{1,2}//g')
				do
					for k in {1..254}
					do
						(ping -c1 $j.$k | grep "bytes from" | cut -d' ' -f4 | sed 's/.$//' \
							| tee -a $path/_sweep/$j.0.alive &)
					done
					randelay

				done
				timeend=$(date +%s.%M)
				echo -e "\n${grn}[+]${end} Took $(echo $timeend - $timestart | bc -l) seconds to sweep network $i.."
			done
			echo -e "${grn}[+]${end} Ping sweep completed. Output saved on $(pwd)/_sweep"
			;;
		[Nn]|[Nn][Oo])
			show_main_menu
			;;
		*)
			clear
			show_banner
			ping_sweep
			;;
	esac

}

## [4] Port Scan

function port_scan
{
	echo port_scan
}

## [5] Domain Enumeration

function download_indexfile
{
	echo -e "${grn}[+]${end} Domain Targets:\n
$(grep DOMAINS $path/config/autonuc.conf | sed 's/DOMAINS=//' | tr -d '"')\n"
	echo -ne "${ylw}[>]${end} Do you want to start enumerating Domains specified? [y/N]>> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			h_code=(200 301 302)
			randelay
			echo -e "${prp}[*]${end} Downloading index.. of target domains"
			
			for i in $(grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"')
			do
				# Check if status code of website is in h_code
                		if [[ ${h_code[*]} =~ (^|[[:space:]])$(curl -sI $i | head -n1 | cut -d' ' -f2)($|[[:space:]]) ]]
				then
					echo -e "${prp}[*]${end} Downloading index for $i.."
					wget $i -O $path/_domain/raw/$i.index.html -q
					echo -e "${grn}[+]${end} Downloaded index of $i.."
				else
					echo -e "${red}[-]${end} Error, Unable to download index file of $i.."
				fi
			done
			;;
		[Nn]|[Nn][Oo])
			show_main_menu
			;;
		*)	
			clear
			show_banner
			download_indexfile
			;;
	esac



}

function scrape_subdomains
{
	randelay
	echo -e "${prp}[*]${end} Scraping for subdomains.."
	
	for i in $(grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"')
	do
		grep -o '[A-Za-z0-9_\.-]'*$i $path/_domain/raw/$i.index.html \
			| sort -u >> $path/_domain/data/$i.subdomains.txt
		randelay
		echo -e "${grn}[+]${end} Subdomains in $i scraped.."
	done	
}

function capture_ipaddresses
{
	randelay
	echo -e "${prp}[*]${end} Capturing IP addresses.."

	for i in $(grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"')
	do
		for j in $(cat $path/_domain/data/$i.subdomains.txt)
		do
			host $j | grep "has address" | awk '{print $4}' >> $path/_domain/result/$i.ipaddresses
		done
		echo -e "${grn}[+]${end} Captured IP addresses of $i.."
		randelay
	done
	randelay

}

function domain_portscan
{
	echo -e "${prp}[*]${end} Scanning ports of target IP addresses.."
	for i in $(grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"')
	do
		echo -e "${prp}[*]${end} Port Scan on domain $i will take a while.. please wait..\n"
		randelay
		for j in $(cat $path/_domain/result/$i.ipaddresses)
		do	
			timestart=$(date +%s.%N)
			nmap --min-rate 3000 -vv $j -p1-$(grep PORT $path/config/autonuc.conf | sed 's/PORT=//') \
				| grep "Discovered open port" | awk {'print $6":"$4'} | awk -F/ {'print $1'} \
				| tee -a $path/_domain/httpx/$i.open
			timeend=$(date +%s.%N)
			echo -e "\n${grn}[+]${end} Scan took: $(echo $timeend - $timestart | bc -l) seconds to finish.."
		done
		echo -e "${grn}[+]${end} Port scan for $i, Completed."
	done
}

function httpx_translate
{
	echo -e "${prp}[*]${end} Preparing targets for nuclei.."
	randelay
	
	for i in $(grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"')
	do
		for j in $(cat $path/_domain/httpx/$i.open)
		do
			echo $j | httpx -silent >> $path/_domain/httpx/$i.httpx
		done
		echo -e "${grn}[+]${end} httpx target on $i ready."
	done
	
	randelay
	echo -e "${grn}[+]${end} Done. Output saved on $(pwd)/_domain"
}

## [6] Nuclei Staged

function nuclei_vascan
{
	echo -e "${blu}Scan target httpx ip addresses in directories\n${end}"
	echo -e "${ylw}[>]${end} Select Target Directory:

[1] $(pwd)/_ports
[2] $(pwd)/_domain
[3] Custom Directory
[4] Back
"

	read -p ">> " getopt

	case $getopt in
		[1]|[_][Pp][Oo][Rr][Tt][Ss])
			echo b
			;;
		[2]|[_][Dd][Oo][Mm][Aa][Ii][Nn])
			clear
			show_banner
			randelay
			for i in $(ls -l $path/_domain/httpx/*.httpx | cut -d' ' -f9)
			do
				echo -e "${grn}[+]${end} Selected $(pwd)/domain path.."
				echo -e "${prp}[*]${end} Starting nuclei on target $(echo $i | cut -d'/' -f4).."
				echo -e "${ylw}[>]${end} Files will be saved on $(pwd)/_nuclei/results..\n"
				
				timestart=$(date +%s.%N)
				cat $i | nuclei -silent -rl 300 -ni -t $path/_nuclei/nuclei-templates/all \
					| tee -a $path/_nuclei/results/$(echo $i | cut -d'/' -f4).nuclei
				timeend=$(date +%s.%N)
				echo -e "\n${grn}[+]${end} Took $(echo $timeend - $timestart | bc -l) for $(echo $i | cut -d'/' -f4) to finish.."

			done
			;;
		[3]|[Cc][Uu][Ss][Tt][Oo][Mm])
			echo a
			;;
		[4]|[Bb][Aa][Cc][Kk])
			show_main_menu
			;;
		*)
			show_banner
			nuclei_vascan
			;;
	esac
}

## [7] View Config

function show_config
{
	less $path/config/autonuc.conf
}

## [8] Update Nuclei Templates / Nuclei Templates

function show_templates_count
{
	if [[ $(ls -l $path/_nuclei/nuclei-templates/all | wc -l) -eq 1 ]]; then
		echo -e "${prp}[*]${end} Available Templates: 0"
	else
		echo -e "${prp}[*]${end} Available Templates: $(ls -l $path/_nuclei/nuclei-templates/all/ | wc -l)"
	fi
}

function update_template
{
	echo -ne "${ylw}[>]${end} Do you want to fetch new templates from github? [y/N]>> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			echo -e "${prp}[*]${end} Updating nuclei templates from github.."
			randelay

			if [[ $(curl -sI https://github.com/projectdiscovery/nuclei-templates | head -n1 | cut -d' ' -f2) == "200" ]]; then
				rm -rf $path/_nuclei/nuclei-templates 2>/dev/null && echo
				git clone https://github.com/projectdiscovery/nuclei-templates $path/_nuclei/nuclei-templates && echo
				mkdir -p $path/_nuclei/nuclei-templates/all 2>/dev/null
				find $path/_nuclei/nuclei-templates -type f -name *.yaml | xargs -I % cp % $path/_nuclei/nuclei-templates/all 2>/dev/null
			else
				echo -e "${red}[-]${end} Update failed. Please check internet connection :("
				pause_screen
			fi
			
			echo -e "${grn}[+]${end} Update Succeeded. Done."
			show_templates_count
			;;
		[Nn]|[Nn][Oo])
			show_main_menu
			;;
		*)
			show_banner
			show_templates_count
			update_template
			;;
	esac
}	

## [9] Clear all data

function clear_alldata
{
	_domain_dir=(raw result data httpx)
	_nuclei_dir=(result)

	echo -ne "${ylw}[>]${end} Do you want clear all gathered data? [y/N]>> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			randelay
			echo -e "${red}[!]${end} Clearing data in _domain directory.."
			for i in ${_domain_dir[@]}
			do
				echo -e "${red}[-]${end} Deleting files from _domain/$i directory.."
				rm -rf $path/_domain/$i/* 2>/dev/null
				randelay
			done
			randelay
			echo -e "${grn}[+]${end} _domain directory purged. Done.\n"
			echo -e "${red}[!]${end} Clearing data in _nuclei directory.."
			for i in ${_nuclei_dir[@]}
			do
				echo -e "${red}[-]${end} Deleting files from _nuclei/$i directory.."
				rm -rf $path/_nuclei/results/* 2>/dev/null
				randelay
			done
			randelay
			echo -e "${grn}[+]${end} _nuclei/results directory purged. Done.\n"
			echo -e "${red}[!]${end} Clearing data in _sweep directory.."
			randelay
			rm -rf $path/_sweep/* 2>/dev/null
			echo -e "${grn}[+]${end} _sweep directory purged. Done.\n"
			;;
		[Nn]|[Nn][Oo])
			show_main_menu
			;;
		*)
			clear
			show_banner
			clear_alldata
			;;
	esac

}
