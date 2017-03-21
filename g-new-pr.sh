#!/usr/bin/env bash

repo_path=$(git config --get remote.origin.url | sed -r 's/(.*:)(.*)(\..*)/\2/')

function getHelp {
    echo "Create a new Pull Request
With no arguments it asks for the dynamically.

    -h|--help       Show this help, then exit
    -c|--custom     The mode where everything is asked
\n"
}

if [ -z ${GITHUB_USER+x} ] || [ -z ${GITHUB_PASSWORD+x} ] && [ -z ${GITHUB_TOKEN+x} ]; then
    printf "If you want to move the task you should set the environment variables bellow:
    \e[33mGITHUB_USER
    GITHUB_PASSWORD
    OR
    GITHUB_TOKEN\e[0m\n"
    exit 1
fi

custom=0

args=("$@")
for i in "$@"
do
    if [[ "$i" = "-h" ]] || [[ "$i" = "--help" ]]; then
       printf "$(getHelp)"
       exit 0
    elif [[ "$i" = "-c" ]] || [[ "$i" = "--custom" ]]; then
        custom=1
    elif [[ "$i" =~ ^- ]]; then
        echo "Invalid parameter: $i"
        exit 1
    fi
done

get_current_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/ ' | tr -d '[:space:]'
}

echo "Making a push of your local branch"
git push origin $(get_current_branch)

originBranch=""
destinationBranch=""
issue_number=""

printf "\n"
read -p "This PR is related to which issue (Default: none): " issue_number

issue_desc=""
[ ! -z "$issue_number" ] && {
    issue_desc="# Este PR é relacionado a qual issue?\n\nConnected to #$issue_number"

    if [ ! -z ${GITHUB_TOKEN+x} ]; then
        issue_exists=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo_path/issues/$issue_number | grep message)
    else
        issue_exists=$(curl -s -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo_path/issues/$issue_number | grep message)
    fi

    if [[ $issue_exists == *"Not Found"* ]]; then
        printf "\e[33mNo issue with this ID was found\e[0m\n"
        exit 1
    fi
}

[[ $custom -eq 1 ]] && {
    printf "\n"
    read -p "Type your origin branch (Default: $(get_current_branch)): " originBranch
}

[ -z "$originBranch" ] && {
    originBranch=$(get_current_branch)
}

[ $custom -eq 1 ] && {
    printf "\n"
    read -p "Type your destination branch (Default: master): " destinationBranch
}

[ -z "$destinationBranch" ] && {
    destinationBranch="master"
}

printf "\n"
read -p "Type the title of your PR (Default: $originBranch): " title

[ -z "$title" ] && {
    title=$originBranch
}

addinfo=""
printf "\n"
read -p "Type any additional information (optional): " addinfo

[ $custom -eq 1 ] && {
    printf "\n"
    read -p "Type the stage of your PR (Default: Review): " stage
}

[ -z "$stage" ] && {
    stageLabel="[\"Stage: Review\"]"
} || {
    stageLabel="[\"Stage: $stage\"]"
}

printf "\n"

data="{ \"title\": \"$title\", \"body\": \"$issue_desc \n\n$addinfo \n\n**Criado via CLI**\", \"head\": \"$originBranch\",  \"base\": \"$destinationBranch\" }"

if [ -z ${GITHUB_TOKEN+x} ]; then
    request_return=$(curl -s -X POST -H "Content-Type: application/json" -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo_path/pulls -d "$data")
    # issue_url=${request_return} | python -m json.tool | sed -n -e '/"issue_url":/ s/^.*"\(.*\)".*/\1/p'
    # curl -s -H "Authorization: token $GITHUB_TOKEN" "$issue_url/labels" -d "$stageLabel" >/dev/null
else
    request_return=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo_path/pulls -d "$data")
fi

if [[ $request_return == *"Validation Failed"* ]]; then
    exit 1
fi

[ ! -z "$issue_number" ] && {
    if [ ! -z ${GITHUB_TOKEN+x} ]; then
        curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo_path/issues/$issue_number/labels/Stage%3A%20In%20Progress >/dev/null
        curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo_path/issues/$issue_number/labels -d '["Stage: Review"]' >/dev/null
    else
        curl -s -X DELETE -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo_path/issues/$issue_number/labels/Stage%3A%20In%20Progress >/dev/null
        curl -s -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo_path/issues/$issue_number/labels -d '["Stage: Review"]' >/dev/null
    fi
}

echo "New Pull Request was created"
pr_url=$(echo ${request_return} | python -m json.tool | sed -n -e '/"html_url":/ s/^.*"\(.*\)".*/\1/p')
pr_url=(${pr_url[@]})
echo "${pr_url[0]}"
