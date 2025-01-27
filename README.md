# vps-setup-docs
Documentation on vps setup

## 1. Backup PostgreSQL database to google drive using rclone
- install rclone
- copy and setup the scripts variables
- test it by running the script
- do chmod +x backup_postgresql.sh if you got permission error
- use crontab -e to add to the os scheduler
- tested on ubuntu 22 and postgres 14