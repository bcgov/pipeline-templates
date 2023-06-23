#!/bin/bash


trap exit SIGINT;
# set -o errexit

readonly REQUIRED_ENV_VARS=(
  "NAMESPACE"
  "OC_LOGIN_STRING"
  "GITHUB_PAT")\

# ask user to input value so that we don't leave secrets in any plain text
ask-for-env(){

    echo Hello! To start with this Tekton setup, I need couple things from you:
    read -p 'Namespace full-name(ex: 101ed4-tools): ' NAMESPACE

    # tekton.sh required env variable 
    export NAMESPACE=$NAMESPACE

    read -p 'OC login sting that you can find on your console page:(whole string including oc) ' OC_LOGIN_STRING
    # Use the ${variable/pattern/replacement} syntax to replace the first occurrence of the string " login " (note the spaces) with namespace
    modified_string="${OC_LOGIN_STRING/ login / login -n $NAMESPACE }"
    echo "$modified_string"

    output=$(eval "$modified_string"|tr -d '\n' )

    while [[ $output != *"Using project \"$NAMESPACE\"."* ]]
        do 
            echo Your login string is not valid, please try again
            read -p 'OC login sting that you can find on your console page:(whole string including oc) ' OC_LOGIN_STRING
            modified_string="${OC_LOGIN_STRING/ login / login -n $NAMESPACE }"
            output=$(eval "$modified_string" | tail -n 1)
            echo "$output"
        done
    echo "Login successed!"
    read -p 'Your Github Personal Access Token(required): ' GITHUB_PAT
     export GITHUB_PAT=$GITHUB_PAT
    sed -i "s/github-pat-token=/github-pat-token=$GITHUB_PAT/g" ./overlays/secrets/secrets.ini

    read -p 'Your sonar Token(not mandatory): ' SONAR_TOKEN
    sed -i "s/sonar-token=/sonar-token=$SONAR_TOKEN/g" ./overlays/secrets/secrets.ini
    


    # tekton.sh required env variable 
    export CONTEXT=`oc config current-context`

}

# Verify the environment vars are set.
verify_env_vars() {
  for evar in ${REQUIRED_ENV_VARS[@]}; do
    if [[ -z "${!evar}" ]]; then
      echo "Err: The env var '$evar' must be set."
      exit 1
    fi
  done
}

init_install(){
echo "Environment setup has been completed, now what you want to do with ./tekton.sh ?"
    script_completed=false
    while   [ "$script_completed" == false ]
    do 
        ./tekton.sh
        read -p 'Which option you want to use? ' option
        ./tekton.sh $option
        if [ $? -eq 0 ]; then
            echo "Finished!!"
            script_completed=true
        else
            echo "tekton.sh returned: $?"
            exit 1
        fi
    done

}

main() {
  ask-for-env
  verify_env_vars
  init_install
}

main "$@"
