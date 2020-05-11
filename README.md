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
* linuxserver/nzbget  


edit: i have added docker-compose.yml  

-to start docker-compose  
docker-compose up -d  

-to stop containers  
docker-compose stop  

-to remove containers  
docker-compose down  

-to update images (remove containers, update images and start docker-compose again)  
docker-compose pull  


default password of deluge is "deluge".  
you must set deluge download path as "/downloads/incompleted", then move to "/downloads/completed"  
(don't forget to create those folders)

add deluge to sonarr/radarr with container hostnames and original port. 
host: "deluge" and port: "8112"  

jacket api link is,  
http://jackett:9117/api/v2.0/indexers/all/results/torznab/  


Nzbget Webui can be found at your-ip:6789 and the default login details (change ASAP) are  
login:nzbget, password:tegbzn6789  