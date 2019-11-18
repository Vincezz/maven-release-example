#!/bin/bash
snapshotSuffix="-SNAPSHOT"
currentVersion=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
releaseVersion=${currentVersion%"$snapshotSuffix"}
releaseType="feature"


# break down the version number into it's components
# ${major}.${minor}.${build}
regex="([0-9]+).([0-9]+).([0-9]+)"
if [[ $releaseVersion =~ $regex ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  build="${BASH_REMATCH[3]}"
fi

# check paramater to see which number to increment
if [[ "$releaseType" == "feature" ]]; then
  minor=$(($minor + 1))
  build=0
elif [[ "$releaseType" == "bug" ]]; then
  build=$(($build + 1))
elif [[ "$releaseType" == "major" ]]; then
  major=$(($major + 1))
  minor=0
  build=0
fi
developmentVersion=${major}.${minor}.${build}-SNAPSHOT

echo "currentVersion=$currentVersion"
echo "releaseVersion=$releaseVersion"
echo "developmentVersion=$developmentVersion"

echo "create branch release/$releaseVersion from develop"
git checkout -b release/"$releaseVersion" develop

mvn test

mvn versions:set -DgenerateBackupPoms=false -DnewVersion="$releaseVersion"
# commit change
git add -u
git commit -m "RELEASE: version $releaseVersion"

git checkout master
git merge release/"$releaseVersion" --no-ff
git tag -a "$releaseVersion" -m "tagging $releaseVersion"

git checkout develop
git merge release/"$releaseVersion" --no-ff

# incrément de la version maven
mvn versions:set -DgenerateBackupPoms=false -DnewVersion="$developmentVersion"
git add -u
git commit -m "CHORE: bump to new version $developmentVersion"

# Removing the release branch
git branch -D release/"$releaseVersion"

git push origin master
git push origin develop
