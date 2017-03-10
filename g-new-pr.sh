#!/usr/bin/env bash

repo_path=$(git config --get remote.origin.url | sed -r 's/(.*:)(.*)(\..*)/\2/')

function getHelp {
    echo "Create a new pull request
With no arguments it asks for the dynamically.

    -c or --custom is the mode where everything is asked
    -dt or --disableTests to disable unit tests from running
    -ds or --disableSchema to disable schema validation from running
\n"
}

if [ -z ${GITHUB_USER+x} ] || [ -z ${GITHUB_PASSWORD+x} ] && [ -z ${GITHUB_TOKEN+x} ]; then
    printf "If you want to move the task you should set the environment variables bellow:
    \e[33mGITHUB_USER
    GITHUB_PASSWORD
    OR
    GITHUB_TOKEN\e[0m\n"
fi

verbose=0
dumb=0
disableTests=0
disableSchema=0

args=("$@")
for i in "$@"
do
    if [[ "$i" = "-h" ]] || [[ "$i" = "--help" ]]; then
       printf "$(getHelp)"
       exit 0
    elif [[ "$i" = "-v" ]] || [[ "$i" = "--verbose" ]]; then
        verbose=1
        echo "Verbose found"
    elif [[ "$i" = "-c" ]] || [[ "$i" = "--custom" ]]; then
        dumb=1
    elif [[ "$i" = "-dt" ]] || [[ "$i" = "--disable-tests" ]]; then
        disableTests=1
    elif [[ "$i" = "-ds" ]] || [[ "$i" = "--disable-schema" ]]; then
        disableSchema=1
    elif [[ "$i" =~ ^- ]]; then
        echo "Invalid parameter: $i"
        exit 1
    fi
    counter=$[$counter + 1]
done

get_current_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

echo "Making a push of your local branch"
git push origin $(get_current_branch)


[[ $dumb -eq 1 ]] && { printf "\n"
    read -p "Type your origin branch (Default: $(get_current_branch)):" originBranch
}

[ -z ${$originBranch+x} ] && {
    originBranch=$(get_current_branch)
}

[ $dumb -eq 1 ] && {
    printf "\n"
    read -p "Type your destination branch (Default: master):" destinationBranch
}

[ -z ${$destinationBranch+x} ] && {
    destinationBranch="master"
}

printf "\n"

read -p "Type the title of your pull request (Default: $originBranch):" title
[ -z ${$title+x} ] && {
    title=$originBranch
}
printf "\n"
read -p "Type the description (at least relate with a card):" description
printf "\n"

data="{ \"title\": \"$title\", \"body\": \"$description **Criado via CLI**\", \"head\": \"$originBranch\",  \"base\": \"$destinationBranch\" }"

if [ -z ${GITHUB_TOKEN+x} ]; then
    curl -s -X POST -H "Content-Type: application/json" -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo_path/pulls -d "$data" > /dev/null
else
    curl -s -X POST -H "Content-Type: application/json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo_path/pulls -d "$data" > /dev/null
fi

echo "New Pull Request was created"
