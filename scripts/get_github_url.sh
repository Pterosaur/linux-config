gh auth login

gh repo list Pterosaur --limit 1000 --json name,sshUrl,url --jq '.[] | "\(.url)"'
gh repo list Pterosaur --limit 1000 --json name,sshUrl,url --jq '.[] | "\(.sshUrl)"'
