export DATE=`date "+%Y%m%d%H%M%S"`
heroku pg:backups:capture --app edit-tosdr-org
heroku pg:backups:download --app edit-tosdr-org
mv latest.dump $DATE.dump
pg_restore --verbose --clean --no-acl --no-owner -d phoenix_development $DATE.dump
rails db:migrate
rm $DATE.dump
