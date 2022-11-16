+++
title = "Spouse Safe Computing"
date = "2022-01-19T17:24:31+02:00"
author = "Noah Kalish"
authorTwitter = "" #do not include @
cover = ""
categories = "linux"
tags = ["openSUSE", "linux", "automation"]
keywords = ["zypper", "transactional updates", "update", "automation"]
#description = ""
showFullContent = false
readingTime = false
draft = true
+++

I love tinkering with my network and making fun things to play with. I've got a k3s cluster running on hardware that was being thrown away. The analytics for this very website are running on that same hardware. (Don't worry, it's umami, and I can't see anything except referrer, URL visited, country, and time spent). I want to constantly improve my home lab and have fun learning the newest tools.

About a year and a half ago I set up a samba share to put movies and TV shows on so my wife and I could enjoy them from any device in our house. The internal conflict that would ensue between the dutiful husband and the sysadmin at play was entirely unexpected. The short version of the story is that I had samba running my wife's old laptop, migrated it to an LXD container, migrated that to a podman container on a new computer, bought some ethernet cable, made a home network, migrated it back to my wife's old laptop, *and then* migrated from samba to NFS. At some point in this transition, my wife's Windows install became unreliable. As I'm not allowed to touch that---and I'm honestly not comfortable enough with Windows to attempt any major repairs---I gave her openSUSE Leap on a high-speed thumb drive. That was the only smart decision I made in that whole mess.

The mistakes I made were many: I did what I found interesting, I tried to solve my problems, I tried to improve stable systems by switching them to more exciting technologies. With every change, I introduced new problems. For example, my last switch over to NFS still has me scratching my head. I have two physical "servers" on the home network---an old laptop and an old desktop. The desktop's NFS shares are perfectly stable. The laptops' constantly cause issues. Both machines are running openSUSE MicroOS and neither has anything in the logs to suggest a problem. The problem is solved by restarting the NFS container. The samba container on the same host works perfectly even when the NFS container is failing. It's a perfect problem for the sysadmin in me to tackle and solve, and I can't wait to figure out what the issue is. However, my wife does not enjoy fixing broken computers. She enjoys watching her TV shows. Every problem is a challenge for me, but it's at the cost of her well-deserved leisure time.

There are many solutions to this problem. I chose the easy way out and put everything that needed to be reliable on a VM, and moved my playground to another VM and the old laptop. The process made me realize that every tinkerer with a family must negotiate and learn "spouse-safe computing." Showing your spouse and kids Plex or Jellyfin is great. What's not great is the phone call the next week when you're at work asking why "the Netflix at home isn't working."
