cd public

#REPOSITORY='https://github.com/bodhi-root/public-wiki.git'
REPOSITORY='git@github.com:bodhi-root/public-wiki.git'
USERNAME='bodhi-root'
USER_EMAIL='bodhi.root@gmail.com'

git init
git remote add origin $REPOSITORY
git checkout -b gh-pages
git fetch origin gh-pages
git reset --soft origin/gh-pages
git config user.name "${USERNAME}"
git config user.email "${USER_EMAIL}"
git add .
git commit -m "Deploying website to Github Pages"
git push --force origin gh-pages:gh-pages
rm -fr .git

cd ..
