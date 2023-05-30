## SELinux

```bash
sudo vi /etc/selinux/config
SELINUX=disabled
setenforce 0
```

## Cerbot

```bash
sudo docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ \
-d mirekng.com \
-d www.mirekng.com \
-d cloud.mirekng.com \
-d git.mirekng.com \
-d transmission.mirekng.com \
-d moodle.mirekng.com
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
