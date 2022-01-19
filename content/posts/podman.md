+++
title = "Containerizing My Home Server"
date = "2022-01-13"
author = "Noah Kalish"
authorTwitter = "" #do not include @
cover = ""
categories = ["linux"]
tags = ["linux", "openSUSE", "containers", "docker", "podman", "Open Build Service"]
keywords = ["linux", "openSUSE", "containers", "docker", "podman"]
description = "One of the best parts of maintaining a hobby server is setting it up. It’s fun to get everything working and figure out all of the quirks of the various pieces of software that have to work together on there. Once it’s working well, it’s a joy to let it sit, auto-update and handle its business for you. Conversely, the worst part of maintaining a hobby server is upgrading the underlying OS to a new release or migrating it to a new platform or machine."
showFullContent = false
readingTime = false
draft = false
+++

## The need for change

One of the best parts of maintaining a hobby server is setting it up. It's fun to get everything working and figure out all of the quirks of the various pieces of software that have to work together on there. Once it's working well, it's a joy to let it sit, auto-update and handle its business for you. Conversely, the worst part of maintaining a hobby server is upgrading the underlying OS to a new release or migrating it to a new platform or machine. I was without CalDAV and CardDAV for about six months because I was too busy to get around to migrating my old data to my new server when I migrated to a better machine.

Choosing to containerize was a decision based on curiousity, hardware limitations, and a desire to learn something new. My initial set up in Israel was my wife's old laptop. With an amazing 4 gigs of RAM, a 100Mbps network card, and a screaming fast dual core AMD E1-1500, it was not a machine that could handle virtualization. My current, new-to-me shiny quad-core i5-2310 with 8 gigs of RAM, 2 SSDs and 2 spinning disks each in a BTRFS raid1 configuration is Watson compared to that old laptop. It's not modern. It also rarely shows a system load above 0.5, so why invest in more? Still, neither machine can handle the number of VMs I would like for some fun at home. I had a choice between containerization and bare metal, and I chose the tinkerer's option.

I am used to running a home server. I've done it on and off since around 2010. I started by just installing everything on there, locking it down, and never backing up. I learned that VMs are your friend after about a year. After many close calls without any serious data loss, I integrated duplicity with an offsite backup sometime around 2013. Things stayed like that for a while until I discovered LXD. Canonical's wrapper around LXC makes containers that work like VMs. It's lightweight and easy to use, but I found the containers to be less portable than VMs. You can use cloud-config to create a container there that just works, but its definition is still tied to the underlying hardware. LXD feels like a crutch to bring VM-style administration to the world of containerization. It works, it's brilliant, but it's stuck between two worlds. Try migrating an LXD image from one mserver to another. I've done it, but it's not as simple as migrating a VM where all the hardware is abstracted away. I decided if I was going to do containerization, I'd do it right, so I looked into learning about Docker and ended up settling on using podman on my server.

## My solution

Since nothing on my server needs 24/7 availability, I prefer to apply patches and upgrades automatically and fix things that break when they break. MicroOS from openSUSE handles this for the base OS. It has never broken for me, and if it does, it has automatic rollbacks so I don't usually have to deal with it. There's a neat feature in podman that handles upgrades for containers: `podman auto-update`. Run this command, and any container labelled with `io.containers.autoupdate=image` will pull a new image and restart if there's an update. There's also a systemd timer that automates this and (at least on openSUSE) can be enabled with `systemctl [--user] enable podman-auto-update.timer`. For anyone looking to switch from Docker, podman has the command `generate systemd. This generates a systemd service file that can be installed to run the containers as system services. If you want them running when the user is not logged in, you'll have to `enable-linger` once on the account running the containers.

Here are the steps:
 
	1. Once for each account that needs to run containers while not logged in run `loginctl enable-linger`. You may need to do this as root, then it's `loginctl enable-linger $NAME_OF_USER_TO_ENABLE`.
	2. Enable auto-updates if desired---also once per account: `systemctl --user enable podman-auto-update.timer`.
	3. Start the container or pod.
	4. Create a systemd service file for the container or pod: `podman generate systemd --files --new --name $NAME_OF_CONTAINER_OR_POD`
	5. Move the service files to `$HOME/.config/systemd/user/`
	6. Reload the service files: `systemctl --user daemon-reload`
	7. Enable the service: `systemctl --user enable [--now] $SERVICE_FILE_NAME`

Here's a breakdown of the above for running nginx as a user named "kube":
```
kube@zoggamule:~> podman ps -a
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
kube@zoggamule:~> loginctl enable-linger #You only ever need to do this once per account
kube@zoggamule:~> systemctl --user enable podman-auto-update.timer # Likewise, once per account here
Created symlink /home/kube/.config/systemd/user/timers.target.wants/podman-auto-update.timer → /usr/lib/systemd/user/podman-auto-update.timer.
kube@zoggamule:~> podman run -d --rm --label io.containers.autoupdate=image --name nginx -p 10080:80 registry.opensuse.org/opensuse/nginx
Trying to pull registry.opensuse.org/opensuse/nginx:latest...
Getting image source signatures
Copying blob 0507b53fa0e9 skipped: already exists
Copying blob 2c6dcd4bd9f9 done
Copying config 9ddf22c9a7 done
Writing manifest to image destination
Storing signatures
f1f2cb7f91f449695ea6bead6bedbb1c90e3cc40b831e044267367685f012bed
kube@zoggamule:~> podman ps -a
CONTAINER ID  IMAGE                                        COMMAND          CREATED         STATUS             PORTS                  NAMES
f1f2cb7f91f4  registry.opensuse.org/opensuse/nginx:latest  /usr/sbin/nginx  46 minutes ago  Up 46 minutes ago  0.0.0.0:10080->80/tcp  nginx
kube@zoggamule:~> podman generate systemd --new --files --name nginx
/home/kube/container-nginx.service
kube@zoggamule:~> ls
bin  container-nginx.service
kube@zoggamule:~> mkdir -p .config/systemd/user
kube@zoggamule:~> mv container-nginx.service ~/.config/systemd/user/
kube@zoggamule:~> systemctl --user daemon-reload
kube@zoggamule:~> systemctl --user enable --now container-nginx.service
Created symlink /home/kube/.config/systemd/user/default.target.wants/container-nginx.service → /home/kube/.config/systemd/user/container-nginx.service.
kube@zoggamule:~> podman ps -a
CONTAINER ID  IMAGE                                        COMMAND          CREATED        STATUS            PORTS                  NAMES
1226a35e009d  registry.opensuse.org/opensuse/nginx:latest  /usr/sbin/nginx  7 seconds ago  Up 7 seconds ago  0.0.0.0:10080->80/tcp  nginx
kube@zoggamule:~> systemctl --user restart container-nginx.service
kube@zoggamule:~> podman ps -a
CONTAINER ID  IMAGE                                        COMMAND          CREATED        STATUS            PORTS                  NAMES
4c47fb5ef7c0  registry.opensuse.org/opensuse/nginx:latest  /usr/sbin/nginx  2 seconds ago  Up 2 seconds ago  0.0.0.0:10080->80/tcp  nginx
kube@zoggamule:~> curl localhost:10080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the container with the nginx web server is
successfully installed and working.</p>
</body>
</html>
kube@zoggamule:~> systemctl --user disable --now container-nginx.service
Removed /home/kube/.config/systemd/user/default.target.wants/container-nginx.service.
```
## The changes

The main change is organizational. Rather than having a mess of files in `/etc/` and data in `/var/`, I put all of my data and configuration for all of my containers in one directory with a directory named for each service. For example, my analytics service, umami has a directory with environment files and database storage for the two containers it uses. The one exception are files served by my webserver. Nextcloud gets a `nextcloud/` folder that holds its database data and environment files, but to make my life easier, I put its html directory in another directory with all of my other sites' web directories. This simplifies the mounts on my nginx container.

The other big change is I try to make everything as simple as possible. I have one template for creating a server block for a new subdomain on nginx. I try to keep it simple so that I can have a new service up in minutes. Just pull the image, create the directories, run it, and copy the config file for the web server. The only part that requires any thought is generating the ssl certificats. I still need to read the docs at [acme.sh](https://acme.sh) every time I do that. The advantage to keeping things simple is that even if something won't migrate easily for whatever reason, it won't be hard to recreate and I'll never go another 6 months without a calendar.

The last *major* change I had to make to my workflow was dealing with config files. I always hated tweaking config files to get things working on a fresh install. Most containers I've worked with have their configs set to sane defaults and allow overrides via environment variables. This simplifies setup considerably. Instead of a config file, I now keep an environment file with *only* my tweaks in it. It saves the trouble of searching through a default file for the right option, and really makes it clear which changes I made to the config if I'm too lazy to set up version control.

I don't use docker compose. Init systems work and do what they do well, so I stick with that. Supposedly, docker-compose works with podman now. I have not tried it because I don't see the need. Anytime a service is offered as a docker-compose file, I simply make a new pod, put the containers into the pod manually, and then run `podman generate systemd` on the pod. Sometimes the service files need to be edited to make sure things load in the right order. Simply modify the `Before=`, `After=`, `Wants=`, or other relevant lines to your needs.

Starting services within a container is refreshingly different than from on a VM. I have a container running SSH that's used as a jump host. Instead of a calling a cryptic init script or relying on a systemd service file somewhere that's doing who knows what, it simply runs `/usr/sbin/sshd -D -f /sshd/sshd_config -p 2222 -e`. It's simple to understand what it's doing, and it's easy to change to fit my needs exactly.

Version control is so much easier. I am working on reorganizing my files and cleaning up some of the systemd service files so they don't contain any sensitive information. Once that's done, I'm putting my server's setup on Github. Backing up data is important, but sometimes the hardest part of a restore is the infrastructure. With everything containerized, I just need a host that can run the containers, my data, and the scripts to start them. My server ran out of disk space because I accidentally had the container images stored on the wrong partition. I had to completely tear down all of my containers and reset podman. To my surprise, once I set the new location and started my systemd services, everything worked just fine. Although it was a bit slow to start as all of the images needed to be downloaded, everything started perfectly and picked up where it left off. It was as easy as migrating a VM. Had I used volume storage, this would not have been the case, but more on that later.

Custom containers initially seem like a pain, but they're worth it. I used to build mine on a local machine until I learned how to use the Open Build Service (OBS) at [build.opensuse.org](https://build.opensuse.org). Instead of fighting someone else's work, I get exactly what I want. One of my next posts will be a tutorial using the OBS.

## Errata

Initially, I followed tutorials, how-tos, and readmes to the last detail. I used container volumes for storage because that's what everyone else seemed to be doing. These are obnoxiously abstracted. They are easy to forget about after a container has outlived its useful life, and they add complexity to a lot of common tasks. Docker's documentation states that volumes are easier to backup or migrate than bind-mounted host directories, and then provides no proof of this fact. In reality, bind-mounting a host directory to a container has perfectly good performance and allows for easier maintainenance. For example, my nginx configs are in a system directory that's mounted on my nginx container. I can edit the files with vim on the host, or I can mount the directory on my laptop and edit the files in any text editor. I can also mount subdirectories of one container's bind mounts to another container without needing to expose the entire mount. I would not have this flexibility with a volume. The same goes for backups. (I've moved from duplicity to restic, by the way.) I don't have to create a container to go mount all my volumes and back them up. I simply place directories that need to be backed up in one main directory and back that up daily. I have not found a compelling reason to use volumes over bind mounts. The system reset I mentioned above was not the first time I did that. When I migrated from the laptop to the i5, Nextcloud was storing its data in volumes. It took me 6 months to get it back up and running because I didn't want to deal with getting the data out of those volumes and onto the new host. Had I used bind-mounted directories, `rsync -avz` would have easily copied all the necessary data and put my site back up in minutes instead of months.

If you need to move your container storage to a new location, you'll lose any volumes when you run `podman system reset`. This is another reason that I avoid storing most things in volumes. I have two exceptions: Data that doesn't need be backed up or moved in a migration such as a redis cache, and volumes automatically created by containers. Occasionally, you'll find a container that overzealously creates volumes or has a volume with an incorrect mount point in its dockerfile. In these cases, I just assign a volume to the mount to keep it out of my hair. If you don't assign a named volume, your system will become cluttered with new, randomly named volumes every time the container starts.

Testing migrations is dead simple. Simply copy a container's mounts to a new location and see if it can work by running it with the mounts changed. If it does, then it's easily migrated to a new host. There are more elegant solutions to this, but they're overkill for a home server.
