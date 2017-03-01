#!/usr/bin/env bash

function getHelp {
    echo "Create a pull request
With no arguments it asks for the dynamically.

    -d or --dumb is the mode where everything is asked
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
    elif [[ "$i" = "-d" ]] || [[ "$i" = "--dumb" ]]; then
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

source $CLIPP_PATH/Cli/lib/cpf-util
source $CLIPP_PATH/Cli/cpf-variables

cd $CLIPP_PATH

#{{{ VALIDATION
[ $disableSchema -eq 0 ] && {
    $CLIPP_PATH/Cli/cpf-schema
    if [ $? != 0 ]; then
        echo "Schema is not in sync"
        exit 1
    fi
}


[ $disableTests -eq 0 ] && {
    $CLIPP_PATH/Cli/cpf-unit-test

    if [ $? != 0 ]; then
        echo "Error on tests cancelling pull request"
        exit 1
    fi
}
#}}}

get_current_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

echo "Making a push of your local branch"
git push origin $(get_current_branch)


[[ $dumb -eq 1 ]] && { printf "\n"
read -p "Type your origin branch (Default: $(get_current_branch)):" originBranch
}

[ $(isEmpty $originBranch) -eq 1 ] && {
    originBranch=$(get_current_branch)
}

[ $dumb -eq 1 ] && {
printf "\n"
read -p "Type your destination branch (Default: master):" destinationBranch
}

[ $(isEmpty $destinationBranch) -eq 1 ] && {
    destinationBranch="master"
}

printf "\n"

read -p "Type the title of your pull request (Default: $originBranch):" title
[ $(isEmpty $title) -eq 1 ] && {
    title=$originBranch
}
printf "\n"
read -p "Type the description (at least relate with a card):" description
printf "\n"

repo="compufour/compufacil"
data="{ \"title\": \"$title\", \"body\": \"$description. **Criado via CLI**\", \"head\": \"$originBranch\",  \"base\": \"$destinationBranch\" }"

if [ -z ${GITHUB_TOKEN+x} ]; then
    curl -X POST -H "Content-Type: application/json" -u $GITHUB_USER:$GITHUB_PASSWORD https://api.github.com/repos/$repo/pulls -d "$data" > /dev/null
else
    curl -X POST -H "Content-Type: application/json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$repo/pulls -d "$data" > /dev/null
fi


gituser=$(git config --get user.name)
cpf-notify-slack "$gituser created a new Pull Request: $title"
cpf-notify-user "The PR $title was created in the remote repository"

cpf-metric "pull-request-created" 1
