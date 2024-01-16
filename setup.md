## SELinux

```bash
sudo vi /etc/selinux/config
SELINUX=disabled
setenforce 0
```

## Cerbot

```bash
sudo docker-compose -f ./services-disabled/certbot.yml --project-dir=. run --rm certbot certonly --expand --cert-name mirekng.com --manual --preferred-challenges dns -d mirekng.com -d \*.mirekng.com
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
