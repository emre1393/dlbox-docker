# downloadbox-docker
### radarr, sonarr, jackett, deluge, bazarr, plex containers with docker-compose   

* i am a newbie with docker.  

* i forked docker-compose.yml from some github repo, i don't remember now, sorry.

(please correct me if i did something wrong)  



used docker containers are,
* linuxserver/radarr  
* linuxserver/sonarr  
* linuxserver/jacket  
* linuxserver/deluge
* linuxserver/bazarr  
* plexinc/pms-docker 


edit: i have added docker-compose.yml


default password of deluge is "deluge".  
you must set deluge download path as "/downloads/incomplete", then move to "/downloads/complete"


jacket api link is,
https://domain.com/jackett/api/v2.0/indexers/all/results/torznab
