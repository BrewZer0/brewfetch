# Brewfetch
Brewy's crap attempt at making a neofetch for old machines.

this is my own neofetch written with very old distros in mind (like Debian 4 and such) in bash with compatible-ish scripts. 

This Fetcher is meant to be simple and compatible so it runs on most (if not all) devices.
in case you're interested (not for sure), you can also use [spitkov's fork](https://github.com/spitkov/brewfetch/) which contains way more stuff (and breaks some). here we're trying to go for simplicity.

and an ELKS-Compatible port may come soon which does the simple task of adapting the current code to run on it.

![hi](https://media.discordapp.net/attachments/1289280325230268456/1320039216779886674/4SzIIWK8.jpg?ex=676825d2&is=6766d452&hm=ee962507f25d81422539778fe9cfafa8d354fa9111dfc0a1d514648c3929b293&)

# How to install

1. git clone the repository (or send it via FTP since most old old linux Distros Don't have git)
2. Turn yourself to root via su (or use sudo)
3. Do the following commands (expecting you're in the Brewfetch directory)

`(sudo) chmod +x bft2.sh
 (sudo) cp bft2.sh /usr/bin/brewfetch
`
