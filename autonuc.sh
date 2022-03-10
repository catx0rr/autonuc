#!/bin/bash
#
#	┌─┐┬ ┬┌┬┐┌─┐╔╗╔╦ ╦╔═╗ ┌─┐┬ ┬
#	├─┤│ │ │ │ │║║║║ ║║   └─┐├─┤
#	┴ ┴└─┘ ┴ └─┘╝╚╝╚═╝╚═╝o└─┘┴ ┴
#
#	| automated nuclei scanning tool |
#
#	Author: Raw Etnerrot (catx0rr)
#	Github: https://github.com/catx0rr/autonuc.git
#
#
# 	Disclaimer: 
#  		Use at your own discretion
#  		I cannot be held responsible for any damages caused. Usage of these tools 
#  		to attack sites, networks, domain is illegal without mutual consent.
#  		I have no liability for any misuse.
#
#	
#	COMMAND HELP:
#		Use the commands below instead of the numbers on the screen.
#	
#	fastscan - Perform Fast, but noisy nuclei scan
#	politescan - Perform Low bandwidth polite nuclei scan
#	pingsweep - Perform ping sweep on target CIDRs or input file
#	portscan - Perform port scan on target CIDRs or input file
#	nucleiscan - Reads a file and perform nuclei scan
#	domainenumerate - Enumerate domains and subdomains and replace it with IP addresses
#	config - View Configuration
#	update - Update new nuclei templates fresh from github repository
#	help - View the help screen
#	quit | exit | x | q - quit autonuc.sh
#
path=`dirname $0`
source $path/config/autonuc.conf

function main
{
	show_menu
}

main

