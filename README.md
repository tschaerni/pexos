pexos - a simple bash-based management tool for syslinux pxe environments
=========

Because there aren't any management tools for a pxe server (there are some webbased ones, but who needs webstuff if you have a CLI?),
I try to write a small script to manage the ISO files on our internal  PXE Boot Server at work, and also for my private one at home.

The goals are to write a somewhat dynamic usable framework which let me add other distros and tools (like Kali, grml, HDT, etc.) within minutes.
The ultimate goal is of course as much as possible to automate, because if you did add some dozens ISO images manually to your PXE server,
you know what I'm talking about...

At the moment pexos is only combatible with the following Distros:
- Ubuntu (32 and 64bit, all "desktop" images, including Ubuntu-Budgie)
- Debian Live Images (32bit and 64bit, only the "live" part of the ISO no support for the included Installer ATM)
- Linux Mint (32 and 64bit, full support)
The list will be enhanced as I add Support for various other stuff.

Some Notes about combatibility:

- Ubuntu 18.04 isn't netbootable atm, that is a bug and (hopefully) fixed in the first point release of the Ubuntu Images
  - Ubuntu 17.10 has some problems with setting up the DNS Server, the systemd-resolver is the source of the problem, possible a bug.
- Linuxmint is fully supported, but after an install you have to delete /etc/network/interfaces and reboot once (don't really know the reason, if you don't do that, ethernet will not work)
- debian is almost fully supported, atleast the live part of the ISO, debian live images have also an installer on board, support for that will come possible in the future.

== Install ==
- write an install guide or something

There is still a lot to do... (inluding the writing of a real readme)

