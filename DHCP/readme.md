# PB-Networking-Playground - DHCP

## Projects

### [Discovery Packet Sender](DiscoveryPacketSender/)&nbsp;&nbsp;<sub><sup>PB</sup></sub>

This one just sends DHCP discovery packets, but it doesn't report back, you can still use Wireshark to see them.<br>
A second small program is included in this project, it just tells you when it probably received some data from a server.


### [Offer Responder](OfferResponder/)&nbsp;&nbsp;<sub><sup>PB</sup></sub>

This programs sends discovery packets and responds to every offer until it received a lease.<br>
The debugger output on this one is more crowded and anarchic, but it should have everything that is relevant to it.<br>
You can still use Wireshark to check the packets more thoroughly.

<b>Warning:</b><br>
Some DHCP servers might react differently if you keep responding to their offers.<br>
The one I tried it on just kept giving me the same unused IP address, but some might just drain the available pool.<br>
Be careful.
