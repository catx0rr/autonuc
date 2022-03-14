#!/bin/bash

function install_banner 
{
	banner='
               __        _   ____  ________
  ____ ___  __/ /_____  / | / / / / / ____/
 / __ `/ / / / __/ __ \/  |/ / / / / /     
/ /_/ / /_/ / /_/ /_/ / /|  / /_/ / /___   
\__,_/\__,_/\__/\____/_/ |_/\____/\____/   
                                           
	        |\**/|      
 	        \ == /
	         |  |
	         |  |
	         \  /
	          \/

[*] Installing autoNUC..'

clear
echo -e "$banner\n"
}

function ready_banner
{
	banner="
	     _.-^^---....,,--       
	 _--                  --_  
	<                        >)
	|                         | 
	 \._                   _./  
	    \`\`\`--. . , ; .--'''       
	          | |   |             
	       .-=||  | |=-.   
	       \`-=#$%&%$#=-'   
	          | ;  :|     
	 _____.,-#%&$@%#&#~,._____
"

echo -e "$banner\n"
echo -e "[+][+][+] autoNUC ready.."
}

function install_go 
{
	echo -e "[*] Installing golang.."
	apt-get -qq install golang-go 1>/dev/null
	#install bc calc
	apt-get -qq install bc 1>/dev/null
	echo -e "[+] Done.."
}

function install_nuclei 
{
	rm -rf ./pkg/nuclei_*.*.*_linux_amd64.zip 2>/dev/null
	echo -e "[*] Installing nuclei.."
	mkdir -p /root/go/bin 2>/dev/null
	sed -i '/PATH/d' /root/.zshrc 1>/dev/null
	echo -e "\nPATH=$PATH:/root/go/bin" >> /root/.zshrc
	mkdir pkg 2>/dev/null
	# current version
	curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases \
		| grep "browser_download_url.*_linux_amd64.zip" \
		| head -n1 \
		| cut -d: -f2,3 \
		| tr -d '"' \
		| wget -qi - -P ./pkg
	# unpacking executable
	unzip pkg/nuclei_*.*.*_linux_amd64.zip -d /root/go/bin 1>/dev/null

	# download templates
		rm -rf ./_nuclei/nuclei-templates 2>/dev/null
		git clone --quiet https://github.com/projectdiscovery/nuclei-templates ./_nuclei/nuclei-templates/ 2>/dev/null
		mkdir -p ./_nuclei/nuclei-templates/all 2>/dev/null
		find ./_nuclei/nuclei-templates -type f -name *.yaml | xargs -I % cp % ./_nuclei/nuclei-templates/all 2>/dev/null
	echo -e "[+] Done.."
}

function install_httpx 
{
	rm -rf ./pkg/httpx_*.*.*_linux_amd64.zip
	echo -e "[*] Installing httpx.."
	# current version
	curl -s https://api.github.com/repos/projectdiscovery/httpx/releases \
		| grep "browser_download_url.*_linux_amd64.zip" \
		| head -n1 \
		| cut -d: -f2,3 \
		| sed 's/"//g' \
		| wget -qi - -P ./pkg
	# unpacking executable
	unzip pkg/httpx_*.*.*_linux_amd64.zip -d /root/go/bin 1>/dev/null
	source /root/.zshrc 2>/dev/null
	echo -e "[+] Done..\n\n"
}

function start_install
{
	echo -ne "[>] Do you want to install all autoNUC required packages?[y/N]>> "
	read getopt

	case $getopt in
		[Yy]|[Yy][Ee][Ss])
			install_banner
			install_go
			install_nuclei
			install_httpx
			ready_banner
			;;
		[Nn]|[Nn][Oo])
			echo -e "[-] Exiting Installer.."
			exit 0
			;;
		*)
			start_install
			;;
	esac
}

start_install
