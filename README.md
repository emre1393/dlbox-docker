# downloadbox-docker
### radarr, sonarr, jackett, deluge, bazarr, plex containers with docker-compose   

* i am a newbie with docker.  

* i forked docker-compose.yml from some github repo, i don't remember now, sorry.

(please correct me if i did something wrong)  


i added "how to" stuff to wiki, check this out.  
https://github.com/emre1393/downloadbox-systemd/wiki  

used docker containers are,
* linuxserver/radarr  
* linuxserver/sonarr  
* linuxserver/jacket  
* linuxserver/deluge
* linuxserver/bazarr  
* plexinc/pms-docker

default password of deluge is "deluge".  
you must set deluge download path as "/downloads/incomplete", then move to "/downloads/complete"

edit: i have added docker-compose.yml
