## SELinux

```bash
sudo vi /etc/selinux/config
SELINUX=disabled
setenforce 0
```

## Cerbot

```bash
sudo docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ \
-d mirekng.com \
-d www.mirekng.com \
-d cloud.mirekng.com \
-d git.mirekng.com \
-d transmission.mirekng.com \
-d moodle.mirekng.com \
-d aria.mirekng.com \
-d tv.mirekng.com \
-d sonarr.mirekng.com \
-d radarr.mirekng.com \
-d bazarr.mirekng.com \
-d prowlarr.mirekng.com \
-d jellyseerr.mirekng.com \
-d yt.mirekng.com
```

## Certbot renew

```bash
sudo docker-compose run --rm certbot renew
```

## Nextcloud cronjob

```bash
sudo crontab -e
*/5 * * * * docker exec -u www-data nextcloud php /var/www/html/cron.php
```

## Nextcloud phone region

```bash
sudo docker-compose exec --user www-data nextcloud php occ config:system:set default_phone_region --value="CZ"
```
