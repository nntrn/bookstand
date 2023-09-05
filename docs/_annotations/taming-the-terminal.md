---
title: Taming the Terminal
author: Bart Busschots
assetid: 1525625941
date: 2022-04-28T21:24:32Z
modified: 2022-04-28T21:28:01Z
tags: "system-administration"
slug: taming-the-terminal
---

## TTT Part 23 of n — Networking Intro

*  You can use the terminal command traceroute (tracert on Windows) to see what routers a packet follows from your computer to my server as follows:

*  In the first window, we'll use the tcpdump command to print out each packet that is sent from your computer to my server as follows: sudo tcpdump -nn host 4..0.5

## TTT Part 26 of n — DHCP

*  Finally, ipconfig can be used to show the DHCP ACK packet that was used to configure a network interface (again replacing enX with the actual interface you want to get the packet for): sudo ipconfig getpacket enX

## TTT Part 27 of n — DNS

*  On most Linux and Unix OSes, DNS resolution is controlled using the configuration file /etc/resolv.conf.
   This file is present in OS X but is used as a way for the OS to expose the settings to scripts and command-line utilities rather than as a way of controlling DNS configuration.
   The file on OS X is in the identical format to the ones on Linux and Unix.
   You can have a look at this file with the command:

