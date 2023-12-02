#!/bin/bash

DEPLOY_INCREMENTS=1

echo "Will deploy cannary-v2 with 3 pods in order to take up 50% of the clients request"

# Configure the output of the v2 deployment
kubectl apply -f index_v2_html.yml
# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml
# Configure the service
kubectl apply -f canary-svc.yml -n udacity
echo "App V2 deployed with 3 pods, serving now 50% of the requests"

echo "If you want to continue with the rollout of the V2 app, continue with the deployment"

function manual_verification {
  read -p "Continue deployment? (y/n) " answer

    if [[ $answer =~ ^[Yy]$ ]] ;
    then
        echo "continuing deployment"
    else
        exit
    fi
}

function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"

  kubectl scale deployment canary-v2 --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS)) -n udacity
  kubectl scale deployment canary-v1 --replicas=$((NUM_OF_V1_PODS - $DEPLOY_INCREMENTS)) -n udacity
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
}


sleep 1
# Begin canary deployment
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -gt 0 ]
do
  manual_verification
  canary_deploy
done

echo "Canary deployment of v2 successful"