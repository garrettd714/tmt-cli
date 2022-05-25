#!/bin/sh

echo "Starting startup.sh..."
echo "Add 5min cron period"
echo "*/5 * * * * run-parts /etc/periodic/5min" >> /etc/crontabs/root
crontab -l
cd /tmt-cli/app
echo "Copy python streamer to tastyworks package"
cp lib/tmt_refresh.py /usr/local/lib/python3.9/site-packages/tastyworks/
echo "Symlinking exes to /usr/local/bin"
ln -s $PWD/exe/tmt /usr/local/bin/
ln -s $PWD/exe/tmt-refresh /usr/local/bin/
# echo "Copying settings from example"
# cp settings.yml.example settings.yml
echo 'export PS1="\e[1;36m[tmt-cli \T>\e[0m \e[1 q"' >> /root/.bashrc
echo "...end startup.sh"
