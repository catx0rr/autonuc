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

function check_projectname
{
	projectname=`echo $PROJECT | sed -E 's/[!@#$%^&*()+?|><,\`~{};:\\/]//g'`

	mkdir $projectname 2>/dev/null
	mkdir -p $projectname/domain 2>/dev/null
	mkdir -p $projectname/domain/httpx 2>/dev/null
	mkdir -p $projectname/domain/raw 2>/dev/null
	mkdir -p $projectname/domain/result 2>/dev/null
	mkdir -p $projectname/domain/data 2>/dev/null
	mkdir -p $projectname/ports 2>/dev/null
	mkdir -p $projectname/ports/httpx 2>/dev/null
	mkdir -p $projectname/ports/result 2>/dev/null
	mkdir -p $projectname/nuclei 2>/dev/null
	mkdir -p $projectname/nuclei/result 2>/dev/null
	mkdir -p $projectname/sweep 2>/dev/null
}

function get_webports
{
	local webports=`echo 66,80,81,443,457,1080,1100,1241,1352,1433,1434,1521,1944,2301,3000,3128,3306,4000,4001,4002,4100,5000,5432,5800,5801,5802,6346,6347,7001,7002,8080,8443,8888,30821 \
		| tr '\n' ',' | sed 's/.$//' | sed 's/,445//'`
	echo $webports
}

function get_config_values
{
	local config=`grep TARGETS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/TARGETS=//' | tr -d '"'`
	echo $config
}

function file_validate
{
	echo $getfilepath
	inputfile=`grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/24' $getfilepath | sed 's/,/\n/g' | sed 's/,$//g' | tr -d '"'`
	echo $inputfile
	cat $getfilepath
}

function config_validate
{
	config=`grep TARGETS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/TARGETS=//' | tr -d '"'`
	randelay

	for i in $config
	do
		if [[ $i == `echo $i | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/24'` ]]
		then
			return 0
		elif [[ $i == `echo $i | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/16'` ]]
		then
			cidr=`ipcalc -n $(echo $i) | grep HostMin | cut -d' ' -f4`
			
			
			for j in {1..255}
			do
				echo $cidr | sed -E "s/\.0/.$j/g" | sed -E 's/\.1$/\.0\/24/g' >> $path/$PROJECT/.slash16.cidr
			done

		else
			clear
			show_banner
			echo -e "${prp}[*]${end} Validating configuration.."
			echo -e "${prp}[*]${end} Scan targets in the configuration file\n"
			echo -e "${ylw}[>]${end} Targets:\n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
			echo -e "${prp}[*]${end} Sweeping target networks.."
			randelay
			echo -e "${red}[-]${end} Stopped Execution.. There is an error on the config file."
			pause_screen
			show_main_menu

		fi
	done
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
			echo -e "${prp}[*]${end} Validating configuration.."
			config_validate
			cidr=$(get_config_values)

			echo -e "${prp}[*]${end} Scan targets in the configuration file"
			
			if [[ $i == `echo $i | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/16'` ]]
			then
				for i in `echo $cidr | sed 's/ /\n/g'`
				do
					echo -e "${red}[!]${end} Detected /16 network(s). Scanning may take a while.."
					echo -e "${prp}[*]${end} Preparing Scan..\n"
					randelay
					echo -e "${ylw}[>]${end} Target(s):\n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
					echo -e "${prp}[*]${end} Sweeping target network(s).."
					echo -e "${grn}[+]${end} Start sweep on target $i..\n"
					timestart=`date +%s.%N`
					
					for j in `cat $path/$PROJECT/.slash16.cidr | sed -E 's/\.[0-9]{1,3}\/[0-9]{1,2}//g'`
					do

						for k in $j
						do
							for l in {1..254}
							do
								(ping -c1 $k.$l | grep "bytes from" | cut -d' ' -f4 | sed 's/.$//' \
									| tee -a $path/$PROJECT/sweep/$PROJECT-$k.0.sweep &)
							done
							randelay
						done
					
				
					done
					timeend=`date +%s.%N`
					echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` seconds to sweep network $i.." 
				done
				
				rm -rf $path/$PROJECT/.slash16.cidr

			else
				echo -e "\n${ylw}[>]${end} Target(s):\n
${grn}{${end} `grep TARGETS $path/config/autonuc.conf | sed 's/TARGETS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
				echo -e "${prp}[*]${end} Sweeping target network(s).."
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
								| tee -a $path/$PROJECT/sweep/$PROJECT-$j.0.sweep &)
						done

					done
					timeend=`date +%s.%N`
					randelay
					echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` seconds to sweep network $i.."
				done

			fi
			
			cat $path/$PROJECT/sweep/*.sweep | sort -u > $path/$PROJECT/sweep/ALL_"$PROJECT".sweep
			echo -e "${grn}[+]${end} Ping sweep completed. Output saved on `pwd`/$PROJECT/sweep"
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
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/$PROJECT/sweep..\n"
	
				timestart=`date +%s.%N`
				cat $getfilepath | nuclei -silent -rl 300 -ni -t $path/$PROJECT/nuclei/nuclei-templates/all \
					| tee -a $path/$PROJECT/nuclei/result/`echo $filename`.nuclei
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
	_http_codes=(200 301 302)
	echo -e "${prp}[*]${end} Validating configuration..\n"
	randelay

	domains=`grep DOMAINS $path/config/autonuc.conf | sed 's/DOMAINS=//' | tr -d '"' | sed 's/,/\n/g'`
	for i in $domains
	do 
		if [[ $i =~ ^([A-Za-z0-9_-]{2,10})+(\.[A-Za-z0-9_-]{2,68})+(\.[A-Za-z]{2,10})?$ ]]
		then
			echo -ne ""		
		else
			echo -e "${red}[-]${end} Stopped Execution.. There is an error on the config file.."
			randelay
			pause_screen
			show_main_menu
		fi

	done
			
	echo -e "${ylw}[>]${end} Domain Targets:\n
${grn}{${end} `grep DOMAINS $path/config/autonuc.conf | sed 's/DOMAINS=//' | tr -d '"' | sed 's/,/, /g'` ${grn}}${end}\n"
	echo -ne "${ylw}[>]${end} Do you want to start enumerating Domains specified? [y/N]: "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			randelay
			echo -e "\n${prp}[*]${end} Downloading index.. of target domains"
			
			for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
			do
				
				# Check if status code of website is in http_codes
                		if [[ ${_http_codes[*]} =~ (^|[[:space:]])$(curl -sI $i | head -n1 | cut -d' ' -f2)($|[[:space:]]) ]]
				then
					echo -e "${prp}[*]${end} Downloading index for $i.."
					wget $i -O $path/$PROJECT/domain/raw/$i.index.html -q
					echo -e "${grn}[+]${end} Downloaded index of $i.."
				else
					echo -e "${red}[-]${end} Error, Unable to download index file of $i.."
				fi
			done
			cat $path/$PROJECT/domain/raw/*.index.html >> $path/$PROJECT/domain/raw/ALL_"$PROJECT".index.html 2>/dev/null
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
	echo -e "\n${prp}[*]${end} Scraping for subdomains.."
	
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		echo
		grep -o '[A-Za-z0-9_\.-]'*$i $path/$PROJECT/domain/raw/$i.index.html \
			| sort -u | tee -a $path/$PROJECT/domain/data/$i.subdomains
		randelay
		echo -e "\n${grn}[+]${end} Subdomains in $i scraped.."
	done	
	cat $path/$PROJECT/domain/data/*.subdomains >> $path/$PROJECT/domain/data/ALL_"$PROJECT".subdomains 2>/dev/null
}

function capture_ipaddresses
{
	randelay
	echo -e "${prp}[*]${end} Capturing IP addresses..\n"

	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		for j in `cat $path/$PROJECT/domain/data/$i.subdomains`
		do
			host $j | grep "has address" | awk '{print $4}' | tee -a $path/$PROJECT/domain/result/$i.ips
		done
		
		echo -e "\n${grn}[+]${end} Captured IP addresses of $i..\n"
	done
	cat $path/$PROJECT/domain/result/*.ips >> $path/$PROJECT/domain/result/ALL_"$PROJECT".ips 2>/dev/null

}

function domain_portscan
{
	echo -e "${prp}[*]${end} Scanning ports of target IP addresses.."
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		ports=$(get_webports)
		timestart=`date +%s.%N`
		echo -e "${prp}[*]${end} Port Scan on domain $i will take a while.. please wait..\n"
		randelay
		
		for j in `cat $path/$PROJECT/domain/result/$i.ips`
		do	
			nmap --min-rate 3000 -vv $j -p $ports \
				| grep "Discovered open port" | awk {'print $6":"$4'} | awk -F/ {'print $1'} \
				| tee -a $path/$PROJECT/domain/httpx/$i.open
		done
		
		timeend=`date +%s.%N`
		echo -e "\n${grn}[+]${end} Scan took: `echo $timeend - $timestart | bc -l` seconds to finish.."
		echo -e "${grn}[+]${end} Port scan for $i, Completed."
	done
	cat $path/$PROJECT/domain/httpx/*.open >> $path/$PROJECT/domain/httpx/ALL_"$PROJECT".open 2>/dev/null
}

function httpx_translate
{
	echo -e "${prp}[*]${end} Preparing targets for nuclei..\n"
	randelay
	
	for i in `grep DOMAINS $path/config/autonuc.conf | sed 's/,/\n/g' | sed 's/DOMAINS=//' | tr -d '"'`
	do
		for j in `cat $path/$PROJECT/domain/httpx/$i.open`
		do
			echo $j | httpx -silent | tee -a $path/$PROJECT/domain/httpx/$i.httpx
		done
		
		echo -e "\n${grn}[+]${end} httpx target on $i ready.\n"
	done
	echo -e "${grn}[+]${end} Done. Output saved on `pwd`/$PROJECT/domain"
}

## [6] Nuclei Staged

function nuclei_vascan
{
	echo -e "${prp}[*]${end} ${blu}Scan target httpx ip addresses in directories\n${end}"
	echo -e "${ylw}[>]${end} Select Target Directory/File:

[1] `pwd`/$PROJECT/ports
[2] `pwd`/$PROJECT/domain
[3] Custom File
[4] Back
"

	read -p ">> " getopt

	case $getopt in
		1|[Pp][Oo][Rr][Tt][Ss])
			clear
			show_banner
			randelay
			
			for i in `ls -l $path/$PROJECT/ports/httpx/*.httpx | cut -d' ' -f9`
			do
				echo -e "${grn}[+]${end} Selected: `pwd`/$PROJECT/ports directory\n"
				echo -e "${prp}[*]${end} Starting nuclei on target ${blu}`echo $i | cut -d'/' -f4`${end}.."
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/$PROJECT/nuclei/result..\n"

				timestart=`date +%s.%N`
				cat $i | nuclei -silent -rl 300 -ni -t $path/$PROJECT/nuclei/nuclei-templates/all \
					| tee -a $path/$PROJECT/nuclei/result/`echo $i | cut -d'/' -f4`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for `echo $i | cut -d'/' -f4` to finish.."
			done
			;;
		2|[Dd][Oo][Mm][Aa][Ii][Nn])
			clear
			show_banner
			randelay
	
			for i in `ls -l $path/$PROJECT/domain/httpx/*.httpx | cut -d' ' -f9`
			do
				echo -e "${grn}[+]${end} Selected: `pwd`/$PROJECT/domain directory\n"
				echo -e "${prp}[*]${end} Starting nuclei on target ${blu}`echo $i | cut -d'/' -f5`${end}.."
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/$PROJECT/nuclei/result..\n"
				
				timestart=`date +%s.%N`
				cat $i | nuclei -silent -rl 200 -ni -t $path/$PROJECT/nuclei/nuclei-templates/all \
					| tee -a $path/$PROJECT/nuclei/result/`echo $i | cut -d'/' -f4`.nuclei
				timeend=`date +%s.%N`
				echo -e "\n${grn}[+]${end} Took `echo $timeend - $timestart | bc -l` for `echo $i | cut -d'/' -f4` to finish.."

			done
			cat $path/$PROJECT/nuclei/result/*.nuclei >> $path/$PROJECT/nuclei/result/ALL_"$PROJECT".nuclei
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
				echo -e "${ylw}[>]${end} Files will be saved on `pwd`/$PROJECT/nuclei/result..\n"

				timestart=`date +%s.%N`
				cat $getfilepath | nuclei -silent -rl 300 -ni -t $path/$PROJECT/nuclei/nuclei-templates/all \
					| tee -a $path/$PROJECT/nuclei/result/`echo $filename`.nuclei
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
	if [[ `ls -l $path/$PROJECT/nuclei/nuclei-templates/all | wc -l` -eq 1 ]]
	then
		echo -e "${prp}[*]${end} Available Templates: 0"
	else
		echo -e "${prp}[*]${end} Available Templates: `ls -l $path/$PROJECT/nuclei/nuclei-templates/all/ | wc -l` "
		echo -e "${grn}[+]${end} Templates Location: `pwd`/$PROJECT/nuclei/nuclei-templates/all\n"
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
				rm -rf $path/$PROJECT/nuclei/nuclei-templates 2>/dev/null && echo
				git clone https://github.com/projectdiscovery/nuclei-templates $path/$PROJECT/nuclei/nuclei-templates && echo
				mkdir -p $path/$PROJECT/nuclei/nuclei-templates/all 2>/dev/null
				find $path/$PROJECT/nuclei/nuclei-templates -type f -name *.yaml | xargs -I % cp % $path/$PROJECT/nuclei/nuclei-templates/all 2>/dev/null
			else
				echo -e "${red}[-]${end} Update failed. Please check internet connection :("
				pause_screen
			fi
			
			show_templates_count
			echo -e "${grn}[+]${end} Update Succeeded. Done."
			pause_screen
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

	echo -e "${grn}[+]${end} Current project directory: `pwd`/$PROJECT"

	echo -ne "${ylw}[>]${end} Do you want clear all gathered data on current project directory? [y/N]: "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			echo -e "\n${red}[!]${end} Clearing data in ${blu}$PROJECT${end}/domain directory.."
			
			for i in ${_domain_dir[@]}
			do
				echo -e "${prp}[*]${end} Deleting files from ${blu}$PROJECT${end}/domain/$i directory.."
				rm -rf $path/$PROJECT/domain/$i/* 2>/dev/null
			done
			randelay

			echo -e "${grn}[+]${end} ${blu}$PROJECT${end}/domain directory purged. Done.\n"
			echo -e "${prp}[*]${end} Clearing data in ${blu}$PROJECT${end}/ports directory.."

			for i in ${_ports_dir[@]}
			do
				echo -e "${prp}[*]${end} Deleting files from ${blu}$PROJECT${end}/ports/$i directory.."
				rm -rf $path/$PROJECT/ports/$i/* 2>/dev/null
			done
			randelay
			
			echo -e "${grn}[+]${end} ${blu}$PROJECT${end}/ports directory purged. Done.\n"
			echo -e "${prp}[*]${end} Clearing data in ${blu}$PROJECT${end}/nuclei directory.."
			
			for i in ${_nuclei_dir[@]}
			do
				echo -e "${prp}[*]${end} Deleting files from ${blu}$PROJECT${end}/nuclei/$i directory.."
				rm -rf $path/$PROJECT/nuclei/result/* 2>/dev/null
			done
			randelay
			
			echo -e "${grn}[+]${end} ${blu}$PROJECT${end}/nuclei/result directory purged. Done.\n"
			
			echo -e "${prp}[*]${end} Clearing data in ${blu}$PROJECT${end}/sweep directory.."
			rm -rf $path/$PROJECT/sweep/* 2>/dev/null
			echo -e "${grn}[+]${end} ${blu}$PROJECT${end}/sweep directory purged. Done.\n"
			randelay
			
			echo -e "${prp}[*]${end} Deleting used CIDR data in ${blu}$PROJECT${end} directory.."
			rm -rf $path/$PROJECT/.slash16.cidr 2>/dev/null
			randelay
			echo -e "${grn}[+]${end} CIDR data has been purged. Done\n"
			sleep 1
		
			echo -e "${grn}[+]${end} Done.. Purged all data in the current project directory."
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
