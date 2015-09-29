git status | grep deleted | awk '{print $3}' | xargs -I {} git rm {}
git status | grep modified | awk '{print $3}' | xargs -I {} git add {}

