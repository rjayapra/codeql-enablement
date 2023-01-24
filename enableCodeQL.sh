#!/bin/bash
org="demo-security-org"
user="rjayapra"
pat="ghp_xxxxx"
header_auth='Authorization: Bearer '$pat
header_version='X-GitHub-Api-Version: 2022-11-28'
basedir=$(cd "$( dirname "$0" )" && pwd )

#Get list of repos for a user
#echo "Get repos under user"
curl --location --request GET -s 'https://api.github.com/users/'$user'/repos' \
    --header $header_version \
    --header $header_auth | jq .[].full_name > repos_user.txt


#Get list of public repos in organization or under user
echo "Get list of repos in organization or under user"
curl -s --location --request GET 'https://api.github.com/orgs/'$org'/repos' \
    --header $header_version \
    --header $header_auth | jq .[].full_name > repos_org.txt

echo
#Get list of workflows in repo and check if code analysis workflow is added
echo "Check if repo has codeQL workflows enabled"
while read line; do
repo=$(echo $line | tr -d '"')
echo
echo "Validating" $repo
enabled=$(curl -s --request GET  'https://api.github.com/repos/'$repo'/actions/workflows' \
   --header $header_version \
   --header $header_auth | jq .workflows[].path | grep -c codeql)

if [ $enabled -eq 0 ]; then
        echo "CodeQL scanning not enabled; Enabling now..."
        #Identify the language for enabling respective codeql workflow template
        echo "Verifying the language"
        language=$(curl -s --request GET 'https://api.github.com/repos/'$repo'/languages'  \
            --header $header_version  \
            --header $header_auth | jq -r 'keys_unsorted[]' | head -1)

        language=$(echo $language| awk '{print tolower($0)}')
        #for l in "${language[@]}"; do
            echo "Enabling CodeQL for $language"
            template="bin/workflows/codeql-analysis-$language.yml"
            
            if [ -e $template ]; then
                reponame=$(echo $repo | awk -F'/' '{print $2}') 
                rm  -rf work
                mkdir work
                git clone https://github.com/$repo.git work
                cd work
                git checkout -b enable_codeql
                mkdir -p .github/workflows
                cp $basedir/$template .github/workflows/
                git add .github/workflows/
                git commit -m "Adding workflows"
                git push -u origin enable_codeql
                cd ..
                rm -rf work
                response=$(curl -X POST 'https://api.github.com/repos/'$repo'/pulls' \
                    --header "$header_version"  \
                    --header "$header_auth" \
                    -d "{\"title\":\"Add CodeQL template\",\"body\": \"Pull codeql changes to master\",\"head\": \"enable_codeql\",\"base\": \"master\"}" )

                prnumber=$(echo $response| jq .number)
                if [ $prnumber -gt 0 ]; then
                    statusmsg=$(curl -X PUT 'https://api.github.com/repos/'$repo'/pulls/'$prnumber'/merge' \
                    --header "$header_version"  \
                    --header "$header_auth" \
                    -d "{\"commit_message\": \"Valid\"}" | jq .message)
                    echo $repo : $statusmsg

                    curl -s --location --request PUT 'https://api.github.com/repos/'$repo'/actions/codeql-analysis-'$language'.yml/enable' \
                        --header "$header_auth" \
                        --header 'Content-Type: application/json'
                    status=$?    
                    if [ $status -ne 0 ];then
                        echo "There is problem enabling CodeQL for $repo, check the error and retry"
                    fi
                fi           
                
                    

                #Convert the file to base64 format
                #base64 $template | tr -d '\n' > base64.txt
                #data="{ \"message\": \"add codel workflow\", \
                #            \"committer\": { \
                #                \"name\": \"Radhika Jayaprakash\", \
                #                \"email\": \"rjayaprakash@microsoft.com\" \
                #            }, \
                #            \"content\": \"$(base64 $template | tr -d '\n')\" }"
                #Add the workflow file
                #curl -s -v --request PUT 'https://api.github.com/repos/'$repo'/contents/.github/workflows/codeql-analysis-'$language.yml \
                #    --header "$header_auth" \
                #    --header "Accept: application/vnd.github+json" \
                #    --data-raw  "$data" 
                #
                #status=$? 
                #if [ $status -ne 0 ];then
                #    echo "Successfully enabled CodeQL for $repo"
                #else 
                #    #Enable the workflow
                #    curl -s --location --request PUT 'https://api.github.com/repos/'$repo'/actions/codeql-analysis-'$language'.yml/enable' \
                #        --header "$header_auth" \
                #        --header 'Content-Type: application/json'
                #    status=$?    
                #    if [ $status -ne 0 ];then
                #        echo "There is problem enabling CodeQL for $repo, check the error and retry"
                #    fi
                #fi
            else
                echo "Template does not exists. Cannot enable CodeQL for $language"
                echo $repo >> repo_codeql_not_enabled.txt
            fi
        #done
    fi
done < repos_org.txt
exit 0
