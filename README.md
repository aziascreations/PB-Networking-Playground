# PB-Networking-Playground

A collection of small programs and demos who play around with networking in PureBasic. [poke at stuff]

<!-- The readme looks like shit for the moment, but it will be fixed at some point -->

## Categories

The sub-pages for each category will list all the projects in more details and indicated which "OS APIs" were used.

### Protocols

There programs only play around with a single protocol in the layers 2 to 3 of the OSI model.

<b>[ARP](ARP/)</b><br>
There is only a network lister for the moment, but "gratuitous arp" and similar stuff will be added later.

<b>[DHCP](DHCP/)</b><br>
Contains some basic programs that compose, parse and respond to some DHCP packets.

<b>[DNS](DNS/)</b><br>
TODO: Link back to the basic DNS server repo and expand it.

<b>[Wake-On-Lan](WakeOnLan/)</b><br>
Only consists of a magic packet sender.<br>
<br>


### Software

There programs only play around with a specific application in the layers 4 or above of the OSI model.

<b>[Minecraft](Minecraft/)</b><br>
Mostly consists of small tests to parse and emits some basic packets.<br>
<br>


### Other folders

<b>[Includes](Includes/)</b><br>
Only consists of simples includes or other repositories that are or are likely to be used by multiple programs.<br>
<br>


## Credits
&nbsp;&nbsp;● [kebian's post on void7.net](http://void7.net/advertising-linux-minecraft-servers-to-the-lan/)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Showed how minecraft's LAN advertising worked and started my adventures in PB networking libraries.

&nbsp;&nbsp;● [Sab0tag3d's](https://github.com/Sab0tag3d) [MITM-cheatsheet repository](https://github.com/Sab0tag3d/MITM-cheatsheet)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Gave a lot of info and showed some "attacks" that are in this repository. <sub><sup>(ARP & DHCP)</sub></sup>

 


## License & Disclaimer

[Unlicense](LICENSE)

The programs shown and given in this repository is for educational purposes only.<br>
Misuse of these programs can be considered as a crime and could land you a fine or a court date.
