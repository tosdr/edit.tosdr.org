git checkout master
git pull
./db/download.sh
./db/export.sh
cd ../tosdr.org
git checkout master
git pull
git add src
git commit -am"export"
./node_modules/.bin/grunt
cp -r dist/api .
git add dist
git add api
git commit -am"built"
git push
git subtree push --prefix dist 5apps master
cd ../edit.tosdr.org
