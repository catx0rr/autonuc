#!/bin/bash

function randelay
{
	sleep $((RANDOM % 3 + 1))
}

function pause_screen
{
	echo
	read -p "" getopt

	case getopt in
		*) show_main_menu
		;;
	esac
}

function config_validate
{
	config=`grep TARGETS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/TARGETS=//' | tr -d '"'`
	
	for i in $config
	do
		if [[ $i == `echo $i | grep -vE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/24'` ]]
		then
			clear
			show_banner
			echo -e "${prp}[*]${end} Scan targets in the configuration file\n"
			echo -e "${ylw}[>]${end} Targets:\n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
			echo -e "${prp}[*]${end} Sweeping target networks.."
			randelay
			echo -e "${red}[-]${end} Stopped Execution.. There is an error on the file."
			pause_screen
			show_main_menu
		fi
	done
}

function file_validate
{
	echo $getfilepath
	inputfile=`grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/24' $getfilepath | sed 's/,/\n/g' | sed 's/,$//g' | tr -d '"'`
	echo $inputfile
	cat $getfilepath
}

## [1] Fast Scan (Nuc Scan)

function fast_scan
{
	echo fastscan still \"in progress\"
}

## [2] Progressive Scan (Nuc Scan)

function progressive_scan
{
	echo progscan still \" in progress\"
}

## [3] Ping Sweep

function ping_sweep
{
	echo -e "${prp}[*]${end} Scan targets on configuration file or custom file"
	echo -e "${ylw}[>]${end} Select Target:

[1] Configuration File
[2] Custom File 
[3] Back
"
	read -p ">> " getopt

	case $getopt in
		1|[Cc][Oo][Nn][Ff][Ii][Gg])
			clear
			show_banner
			config_validate

			echo -e "${prp}[*]${end} Scan targets in the configuration file\n"
			echo -e "${ylw}[>]${end} Targets:\n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
			echo -e "${prp}[*]${end} Sweeping target networks.."
			randelay
			
			for i in `grep TARGETS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/TARGETS=//' | tr -d '"'`
			do
				echo -e "${grn}[+]${end} Start sweep on target $i..\n"
				timestart=`date +%s.%N`
				
				for j in `echo $i | sed -E 's/\.[0-9]{1,3}\/[0-9]{1,2}//g'`
				do
					for k in {1..254}
					do
						(ping -c1 $j.$k | grep "bytes from" | cut -d' ' -f4 | sed 's/.$//' \
							| tee -a $path/_sweep/$j.0.alive &)
					done

				done
				timeend=`date +%s.%N`
				randelay
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` seconds to sweep network $i.."
			done
			echo -e "${grn}[+]${end} Ping sweep completed. Output saved on `pwd`/_sweep"
			;;
		
		2|[Cc][Uu][Ss][Tt][Oo][Mm])
			clear
			show_banner
			
			echo -ne "${ylw}[>]${end} Enter path file name: "
			read -e getfilepath
	
			if [[ -z "$getfilepath" ]]
			then
				echo -e "${red}[-]${end} No file path entered.."
				randelay
				clear
				show_banner
				ping_sweep
			fi
			
			# Clean
			getfilepath=`echo $getfilepath | sed -E 's/[!@#$%^&*()+?|><,\`~{};:\\]//g'`
			
			# Validate
			file_validate
			echo "still in progress"
			pause_screen

			# Get the last name appear on the path
			filename=`echo $getfilepath | awk -F'/' '{ a = length($NF) ? $NF : $(NF-1); print a }' 2>/dev/null`
			
			

			if [[ -f "$getfilepath" ]]
			then
				echo -e "${grn}[+]${end} Selected file: $getfilepath\n"
				echo -e "${prp}[*]${end} Starting pingsweep on ${blu}$filename${end}"
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/_sweep..\n"
	
				timestart=`date +%s.%N`
				cat $getfilepath | nuclei -silent -rl 300 -ni -t $path/_nuclei/nuclei-templates/all \
					| tee -a $path/_nuclei/result/`echo $filename`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for $filename to finish.."
			else
				echo -e "${red}[-]${end} File does not exist in target directory.."
				randelay
				clear
				show_banner
				nuclei_vascan
			fi
			;;
		
		3|[Bb][Aa][Cc][Kk])
			show_main_menu
			;;
		*)
			show_banner
			ping_sweep
			;;
	esac



}

## [4] Port Scan

function port_scan
{
	echo -e "${prp}[*]${end} Scan targets in the configuration file\n"
	echo -e "${ylw}[>]${end} Targets: \n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
	echo -e "\"still in progress\""
}

## [5] Domain Enumeration

function download_indexfile
{
	echo -e "${ylw}[>]${end} Domain Targets:\n
${grn}{${end} `grep DOMAINS $path/config/autonuc.conf | sed 's/DOMAINS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
	echo -ne "${ylw}[>]${end} Do you want to start enumerating Domains specified? [y/N]: "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			http_codes=(200 301 302)
			randelay
			echo -e "${prp}[*]${end} Downloading index.. of target domains"
			
			for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
			do
				# Check if status code of website is in http_codes
                		if [[ ${http_codes[*]} =~ (^|[[:space:]])$(curl -sI $i | head -n1 | cut -d' ' -f2)($|[[:space:]]) ]]
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
	
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
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

	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		for j in `cat $path/_domain/data/$i.subdomains.txt`
		do
			host $j | grep "has address" | awk '{print $4}' >> $path/_domain/result/$i.ipaddresses
		done
		
		echo -e "${grn}[+]${end} Captured IP addresses of $i.."
	done

}

function domain_portscan
{
	echo -e "${prp}[*]${end} Scanning ports of target IP addresses.."
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		timestart=`date +%s.%N`
		echo -e "${prp}[*]${end} Port Scan on domain $i will take a while.. please wait..\n"
		randelay
		
		for j in `cat $path/_domain/result/$i.ipaddresses`
		do	
			nmap --min-rate 3000 -vv $j -p1-`grep PORT $path/config/autonuc.conf | sed 's/PORT=//'` \
				| grep "Discovered open port" | awk {'print $6":"$4'} | awk -F/ {'print $1'} \
				| tee -a $path/_domain/httpx/$i.open
		done
		
		timeend=`date +%s.%N`
		echo -e "\n${grn}[+]${end} Scan took: `echo $timeend - $timestart | bc -l` seconds to finish.."
		echo -e "${grn}[+]${end} Port scan for $i, Completed."
	done
}

function httpx_translate
{
	echo -e "${prp}[*]${end} Preparing targets for nuclei.."
	randelay
	
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		for j in `cat $path/_domain/httpx/$i.open`
		do
			echo $j | httpx -silent >> $path/_domain/httpx/$i.httpx
		done
		
		echo -e "${grn}[+]${end} httpx target on $i ready."
	done
	
	echo -e "${grn}[+]${end} Done. Output saved on `pwd`/_domain"
}

## [6] Nuclei Staged

function nuclei_vascan
{
	echo -e "${prp}[*]${end} ${blu}Scan target httpx ip addresses in directories\n${end}"
	echo -e "${ylw}[>]${end} Select Target Directory/File:

[1] `pwd`/_ports
[2] `pwd`/_domain
[3] Custom File
[4] Back
"

	read -p ">> " getopt

	case $getopt in
		1|[_][Pp][Oo][Rr][Tt][Ss])
			clear
			show_banner
			randelay
			
			for i in `ls -l $path/_ports/httpx/*.httpx | cut -d' ' -f9`
			do
				echo -e "${grn}[+]${end} Selected: `pwd`/_ports directory\n"
				echo -e "${prp}[*]${end} Starting nuclei on target ${blu}`echo $i | cut -d'/' -f4`${end}.."
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/_nuclei/result..\n"

				timestart=`date +%s.%N`
				cat $i | nuclei -silent -rl 300 -ni -t $path/_nuclei/nuclei-templates/all \
					| tee -a $path/_nuclei/result/`echo $i | cut -d'/' -f4`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for `echo $i | cut -d'/' -f4` to finish.."
			done
			;;
		2|[_][Dd][Oo][Mm][Aa][Ii][Nn])
			clear
			show_banner
			randelay
	
			for i in `ls -l $path/_domain/httpx/*.httpx | cut -d' ' -f9`
			do
				echo -e "${grn}[+]${end} Selected: `pwd`/_domain directory\n"
				echo -e "${prp}[*]${end} Starting nuclei on target ${blu}`echo $i | cut -d'/' -f4`${end}.."
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/_nuclei/result..\n"
				
				timestart=`date +%s.%N`
				cat $i | nuclei -silent -rl 300 -ni -t $path/_nuclei/nuclei-templates/all \
					| tee -a $path/_nuclei/result/`echo $i | cut -d'/' -f4`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for `echo $i | cut -d'/' -f4` to finish.."

			done
			;;
		3|[Cc][Uu][Ss][Tt][Oo][Mm])
			clear
			show_banner
			
			echo -ne "${ylw}[>]${end} Enter path file name: "
			read -e getfilepath
	
			if [[ -z "$getfilepath" ]]
			then
				echo -e "${red}[-]${end} No file path entered.."
				randelay
				clear
				show_banner
				nuclei_vascan
			fi
			
			# Clean
			getfilepath=`echo $getfilepath | sed -E 's/[!@#$%^&*()+?|><,\`~{};:\\]//g'`
			
			# Get the last name appear on the path
			filename=`echo $getfilepath | awk -F'/' '{ a = length($NF) ? $NF : $(NF-1); print a }' 2>/dev/null`
			

			if [[ -f "$getfilepath" ]]
			then
				echo -e "${grn}[+]${end} Selected file: $getfilepath\n"
				echo -e "${prp}[*]${end} Starting nuclei on ${blu}$filename${end}"
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/_nuclei/result..\n"

				timestart=`date +%s.%N`
				cat $getfilepath | nuclei -silent -rl 300 -ni -t $path/_nuclei/nuclei-templates/all \
					| tee -a $path/_nuclei/result/`echo $filename`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for $filename to finish.."
			else
				echo -e "${red}[-]${end} File does not exist in target directory.."
				randelay
				clear
				show_banner
				nuclei_vascan
			fi
			;;
		4|[Bb][Aa][Cc][Kk])
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
	ccat --color="always" $path/config/autonuc.conf | less -r
}

## [8] Update Nuclei Templates / Nuclei Templates

function show_templates_count
{
	if [[ `ls -l $path/_nuclei/nuclei-templates/all | wc -l` -eq 1 ]]
	then
		echo -e "${prp}[*]${end} Available Templates: 0"
	else
		echo -e "${prp}[*]${end} Available Templates: `ls -l $path/_nuclei/nuclei-templates/all/ | wc -l` "
		echo -e "${ylw}[>]${end} Templates Location: `pwd`/_nuclei/nuclei-templates/all\n"
	fi
}

function update_template
{
	echo -ne "${ylw}[>]${end} Do you want to fetch new templates from github? [y/N]: "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			echo -e "${prp}[*]${end} Updating nuclei templates from github.."
			randelay

			if [[ `curl -sI https://github.com/projectdiscovery/nuclei-templates | head -n1 | cut -d' ' -f2` == "200" ]]
			then
				rm -rf $path/_nuclei/nuclei-templates 2>/dev/null && echo
				git clone https://github.com/projectdiscovery/nuclei-templates $path/_nuclei/nuclei-templates && echo
				mkdir -p $path/_nuclei/nuclei-templates/all 2>/dev/null
				find $path/_nuclei/nuclei-templates -type f -name *.yaml | xargs -I % cp % $path/_nuclei/nuclei-templates/all 2>/dev/null
			else
				echo -e "${red}[-]${end} Update failed. Please check internet connection :("
				pause_screen
			fi
			
			show_templates_count
			echo -e "${grn}[+]${end} Update Succeeded. Done."
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
	_ports_dir=(httpx result)

	echo -ne "${ylw}[>]${end} Do you want clear all gathered data? [y/N]: "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			echo -e "${red}[!]${end} Clearing data in _domain directory.."
			
			for i in ${_domain_dir[@]}
			do
				echo -e "${red}[-]${end} Deleting files from _domain/$i directory.."
				rm -rf $path/_domain/$i/* 2>/dev/null
				randelay
			done
			echo -e "${grn}[+]${end} _domain directory purged. Done.\n"
			echo -e "${red}[!]${end} Clearing data in _ports directory.."

			for i in ${_ports_dir[@]}
			do
				echo -e "${red}[-]${end} Deleting files from _ports/$i directory.."
				rm -rf $path/_ports/$i/* 2>/dev/null
				randelay
			done
			
			echo -e "${grn}[+]${end} _ports directory purged. Done.\n"
			echo -e "${red}[!]${end} Clearing data in _nuclei directory.."
			
			for i in ${_nuclei_dir[@]}
			do
				echo -e "${red}[-]${end} Deleting files from _nuclei/$i directory.."
				rm -rf $path/_nuclei/result/* 2>/dev/null
				randelay
			done
			
			echo -e "${grn}[+]${end} _nuclei/result directory purged. Done.\n"
			
			echo -e "${red}[!]${end} Clearing data in _sweep directory.."
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
