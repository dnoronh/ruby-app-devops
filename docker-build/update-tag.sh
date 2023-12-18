#!/bin/bash
new_tag=$1
cd /tmp
git clone https://${GITHUB_TOKEN}@github.com/dnoronh/ruby-app-gitops-repo.git
cd ruby-app-gitops-repo/deployment/ruby-app

cur_tag=$(cat ./values.yaml | grep tag: | awk '{print $2}')
echo "Old image tag: $cur_tag"
echo "New image tag: $new_tag"
sed -i "s/tag: $cur_tag/tag: \"$new_tag\"/" ./values.yaml

echo "Commit and push changes to repo - ruby-app-gitops-repo"
git add -A && git commit -m "Update image version to $new_tag"
git push origin --quiet
rm -rf /tmp/ruby-app-gitops-repo
