# PB-Networking-Playground - Minecraft

## Projects

### [AbuseLanServerDiscovery](https://github.com/aziascreations/MC-155611-Bug-Demonstration)&nbsp;&nbsp;<sub><sup>PB</sup></sub>

This program just spams packets at a theorical maximum of 1000 packets per seconds which causes other instances of the game who are in the multiplayer menu to crash, most of the time.<br>
It was done to see if you could waste a bunch of RAM on the other instances, but it just ended up crashing them because of an unhandled ```ConcurrentModificationException``` in the game's code.

Check the [MC-155611-Bug-Demonstration](https://github.com/aziascreations/MC-155611-Bug-Demonstration) repo for more technical info and the code.

### [AdvertiseLanServer](AdvertiseLanServer/)&nbsp;&nbsp;<sub><sup>PB</sup></sub>

This program just advertises a server on the LAN, it is kinda useless on it's own, unless you want to advertise a headless server on LAN or crash other instances of the game on the network <sub><sup>(See [AbuseLanServerDiscovery](#abuselanserverdiscovery))</sup></sub>

Inspired by [kebian's post on void7.net](http://void7.net/advertising-linux-minecraft-servers-to-the-lan/).