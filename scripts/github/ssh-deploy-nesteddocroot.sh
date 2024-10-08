#!/bin/bash

export PROJECT_ROOT="$(pwd)"
. $PROJECT_ROOT/config  

# sh $PROJECT_ROOT/scripts/github/load-keys
# echo "Host *\n\tStrictHostKeyChecking no\n\n" > "$SSH_DIR/config"
# cat $SSH_DIR/config
# ssh-add -l

cd $PROJECT_ROOT
#rm $PROJECT_ROOT/composer.lock
#composer update
#composer install
#echo 'wp composer build success!!'

ssh-add -l

#sh $PROJECT_ROOT/scripts/github/load-keys
export PATH="$PATH:$COMPOSER_HOME/vendor/bin"
echo "COMPOSER PATH:"$PATH
export PROJECT_ROOT="$(pwd)"
export GITHUB_BRANCH=${GITHUB_REF##*heads/}
printf "[\e[0;34mNOTICE\e[0m] Setting up SSH access to server for rsync usage.\n"
SSH_DIR="$HOME/.ssh"
echo "SSHDIR PATH:"$SSH_DIR

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_DIR/id_rsa1"
touch "$SSH_DIR/config"
#echo "Host *\n\tStrictHostKeyChecking no\n\n" > "$SSH_DIR/config"
#echo "${{ secrets.PANTHEON_PRIVATE_KEY }}" > "$SSH_DIR/id_rsa1"

mkdir -p ~/.ssh && echo "Host *" > ~/.ssh/config && echo " StrictHostKeyChecking no" >> ~/.ssh/config

cd ~
pwd

echo "$PANTHEON_PRIVATE_KEY" > "$SSH_DIR/id_rsa1"
chmod 600 "$SSH_DIR/id_rsa1"
chmod 600 "$SSH_DIR/config"
eval "$(ssh-agent -s)"
eval `ssh-agent -s`
ssh-add "$SSH_DIR/id_rsa1"
ssh-add -l
cat $SSH_DIR/id_rsa1
cat $SSH_DIR/config
cat $SSH_DIR/known_hosts
cat ~/.ssh/known_hosts
ssh-keygen -R hostname
sudo cat ~/.ssh/ssh_config
echo "SSH PRIVATE KEY IMPORTED!!!"

cd $PROJECT_ROOT
ls

# deploy pantheon yml files
rsync -rLvzc --size-only --ipv4 --progress -e 'ssh -p 2222' ./pantheon.yml --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/ --exclude='*.git*' --exclude node_modules/ --exclude gulp/ --exclude source/
printf "[\e[0;34mNOTICE\e[0m] Deployed pantheon.yml file\n"

terminus rsync ./web site-deploy-gh1.dev:code/web 

# deploy wp cli yml file
rsync -rLvzc --size-only --ipv4 --progress -e 'ssh -p 2222' ./wp-cli.yml --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/ --exclude='*.git*' --exclude node_modules/ --exclude gulp/ --exclude source/
printf "[\e[0;34mNOTICE\e[0m] Deployed wp-cli.yml file\n"

# deploy vendor folder
rsync -rLvzc --delete --ipv4 --progress -e 'ssh -p 2222' ./vendor/. --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/vendor/ --update
printf "[\e[0;34mNOTICE\e[0m] Deployed vendor folder\n"

# deploy private folder for quicksilver scripts
rsync -rLvzc --delete --ipv4 --progress -e 'ssh -p 2222' ./web/private/. --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/web/private/ --exclude='*.git*' --exclude node_modules/ --exclude gulp/ --exclude source/
printf "[\e[0;34mNOTICE\e[0m] Deployed private folder for quicksilver scripts\n"

# deploy plugins and themes
rsync -rLvzc --delete --size-only --ipv4 --progress -e 'ssh -p 2222' ./web/wp-content/. --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/web/wp-content/ --exclude='*.git*' --exclude node_modules/ --exclude gulp/ --exclude source/
printf "[\e[0;34mNOTICE\e[0m] Deployed plugin and themes\n"

# deploy core via rsync + wp-config
# rsync -rLvzc --size-only --ipv4 --progress -e 'ssh -p 2222' ./web/wp/. --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/web/wp/ --exclude='*.git*' --exclude node_modules/ --exclude wp-content/ --exclude gulp/ --exclude source/

#dont forget to elete the config to avoid redirect loop
rm $PROJECT_ROOT/web/wp/wp-config.php

# deploy core and root files
rsync -rLvzc --delete --size-only --ipv4 --progress -e 'ssh -p 2222' ./web/. --temp-dir=~/tmp/ $PANTHEONENV.$PANTHEONSITEUUID@appserver.$PANTHEONENV.$PANTHEONSITEUUID.drush.in:code/web/ --exclude='*.git*' --exclude node_modules/ --exclude wp-content/ --exclude gulp/ --exclude source/

terminus art

MSG1="$GH_REF2"
export MSG1
DEPLOYMSG="Complete rebuild. Deployed from GitHub $MSG1"
export DEPLOYMSG
echo "$DEPLOYMSG"
#echo ::set-env name=PULL_NUMBER::$(echo "$GH_REF2" | awk -F / '{print $3}')

terminus env:commit --message "$DEPLOYMSG" --force -- $PANTHEONSITENAME.$PANTHEONENV

printf "[\e[0;34mNOTICE\e[0m] Deployed core and wp-config\n"

# setup backstop script
# sh $PROJECT_ROOT/scripts/github/setup-backstop