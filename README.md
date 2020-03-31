# downloadbox-systemd
### radarr, sonarr, jackett, deluge, bazarr containers with systemd  

* i am a newbie with docker.  

* i prepared 4 systemd file with help from radarr's github docker guide.  

* i will add a user named "docker" with no-login and uid=1000, gid=1000.  
* i will create some folders for these containers.  
* i will set up an nginx reverse proxy with https.  

(please correct me if i did something wrong)  


i added "how to" stuff to wiki, check this out.  
https://github.com/emre1393/downloadbox-systemd/wiki  

used docker containers are,
* linuxserver/radarr  
* linuxserver/sonarr  
* linuxserver/jacket  
* linuxserver/deluge
* linuxserver/bazarr  

not: restart container procedure is,  
`systemctl stop docker-$app && systemctl start docker-$app`  

default password of deluge is "deluge".  
you must set deluge download path as "/downloads/incomplete", then move to "/downloads/complete"
