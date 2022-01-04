---
title: "Simple repository caching on openSUSE"
date: 2022-01-04T15:53:06+02:00
draft: false
tags:
 - linux
 - openSUSE
 - apt-cacher-ng
 - caching proxy
 - zypper
categories:
 - linux
---

One of the things I missed the most from my Debian/Ubuntu days when I switched to openSUSE about a year ago was apt-cacher-ng with proxy autodiscovery. I had apt-cacher-ng running on one computer at home, and all of my containers, VMs, and laptops would use that proxy when they were on the home network. Even better, they'd seemlessly switch back to the default repos if the proxy was unavailable.

To be clear, what I want is to have my computers use apt-cacher-ng as a proxy when available to download packages. When it's unavailable either due to downtime, a bug, or me being on a different network, I want zypper to default to the standard repos.

I tried to find the proper way to do this on openSUSE. I asked on reddit and telegram, but I found no reasonable solutions. I tried creating a transparent caching proxy with squid and some iptables rules, but due to zypper downloading from multiple repositories simultaneously, it needed a lot of hacks to cache the rpms properly. I wasn't willing to risk a duct-taped together solution that could break any day. I tried writing a service for libzypp, but found the documentation unclear and lacking useful examples. Finally, I found a solution so simple I'm surprised I haven't seen it published elsewhere.

After playing with this for a few months on and off I wondered what the spec actually requires of a `.repo` file, and I found [this gem on SUSE's site](https://www.suse.com/support/kb/doc/?id=000019926). You can specify more than one `baseurl`, and their order sets their priority. I looked at the [manpage for zypper](https://www.mankier.com/8/zypper#Commands-Supported_URI_formats) and found that a proxy can be defined in the URI.

The solution is as simple as editing the repo file and adding a `baseurl` point to apt-cacher-ng  before the default `baseurl`. For reference, here's one of my `.repo` files:

```
[repo-oss]
name=openSUSE-Tumbleweed-Oss
enabled=1
autorefresh=1
path=/
baseurl=http://download.opensuse.org/tumbleweed/repo/oss/?proxy=10.42.0.1:3128
baseurl=http://download.opensuse.org/tumbleweed/repo/oss/
keeppackages=0
```

I have noticed the occasional 404 error in the proxy that shouldn't be happening. The errors only seem to occur with metadata files and not the actual packages, so it's serving its main purpose and saving me plenty of time and our cell connection to the internet plenty of bandwidth.

This may work for Fedora, RHEL, and the other rpm distros, but I don't have the time or need to test it out right now.
