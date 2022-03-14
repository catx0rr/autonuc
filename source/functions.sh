#!/bin/bash

function high_radar_scan
{
	show_banner
	fast_scan
	pause_screen
}

function low_radar_scan
{
	show_banner
	progressive_scan
	pause_screen
}

function sweep_target
{
	show_banner
	ping_sweep
	pause_screen
}


function scan_target
{
	show_banner
	port_scan
	pause_screen
}

function enumerate_domain
{
	show_banner
	download_indexfile
	scrape_subdomains
	capture_ipaddresses
	domain_portscan
	httpx_translate
	pause_screen
}

function nuclei_staged_scan
{
	show_banner
	nuclei_vascan
	pause_screen
}

function view_config_call
{
	show_config
	show_main_menu
}

function update_template_call
{
	show_banner
	show_templates_count
	update_template
	pause_screen
}

function clear_data
{
	show_banner
	clear_alldata
	pause_screen
}
