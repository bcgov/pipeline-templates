#!/bin/bash



# set -o errexit

readonly REQUIRED_ENV_VARS=(
  "NAMESPACE"
  "OC_LOGIN_STRING")\

# ask user to input value so that we don't leave secrets in any plain text
ask-for-env(){

    echo Hello! To start with this Tekton setup, I need couple things from you:
    read -p 'Namespace full-name(ex: 101ed4-tools): ' NAMESPACE
    # tekton.sh required env variable 
    export NAMESPACE=$NAMESPACE

    read -p 'OC login sting that you can find on your console page:(whole string including oc) ' OC_LOGIN_STRING

    while ! $OC_LOGIN_STRING
        do 
            echo Your login strying is not valid, please try again
            read -p 'OC login sting that you can find on your console page:(whole string including oc) ' OC_LOGIN_STRING
        done
    oc project $NAMESPACE

    read -p 'Your sonar Token(not mandatory):  ' SONAR_TOKEN
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