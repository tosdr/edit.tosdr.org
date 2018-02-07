rm latest.dump*
heroku pg:backups:capture --app edit-tosdr-org
heroku pg:backups:download --app edit-tosdr-org
pg_restore --verbose --clean --no-acl --no-owner -h localhost -d phoenix_development latest.dump
rails db:migrate
rails runner db/export_points_to_old_db.rb
git checkout -- old_db/points/
git status
