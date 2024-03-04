#!/bin/bash

RESOURCE=$(echo -e "POD\nDEPLOYMENT\nREPLICASET\nSTATEFULSET\nDAEMONSET\nJOB\nCRONJOB\nHORIZONTALPODAUTOSCALING\nSERVICE\nINGRESS\nCONFIGMAP\nSECRET\nPERSISTENTVOLUMECLAIM\nPERSISTENTVOLUME\nSERVICEACCOUNT\nROLE\nROLEBINDING\nCLUSTERROLE\nCLUSTERROLEBINDING\nCUSTOMRESOURCEDEFINITION\nNODE" | fzf --height=25% --border --reverse --prompt='RESOURCE > ')

case $RESOURCE in
  POD)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nWATCH\nLOGS\nEXEC\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
      GET)
        NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        elif [ "$NAMESPACE" = "all-namespaces" ]; then
          CMD="kubectl get pod -A -o wide"
          echo $CMD && eval $CMD
        else
          CMD="kubectl get pod -n $NAMESPACE -o wide"
          echo $CMD && eval $CMD
        fi
        ;;
      YAML)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        POD=$(kubectl get pod -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='POD > ' | awk '{print $1}')
        if [ -z "$POD" ]; then
          echo "No pod selected." && exit 0
        fi
        CMD="kubectl get pod -n $NAMESPACE $POD -o yaml"
        echo $CMD && eval $CMD
        ;;
      DESCRIBE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        POD=$(kubectl get pod -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='POD > ' | awk '{print $1}')
        if [ -z "$POD" ]; then
          echo "No pod selected." && exit 0
        fi
        CMD="kubectl describe pod -n $NAMESPACE $POD"
        echo $CMD && eval $CMD
        ;;
      WATCH)
        NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        elif [ "$NAMESPACE" = "all-namespaces" ]; then
          CMD="watch -n 1 kubectl get pod -A -o wide"
          echo $CMD && eval $CMD
        else
          CMD="watch -n 1 kubectl get pod -n $NAMESPACE -o wide"
          echo $CMD && eval $CMD
        fi
        ;;
      LOGS)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        POD=$(kubectl get pod -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='POD > ' | awk '{print $1}')
        if [ -z "$POD" ]; then
          echo "No pod selected." && exit 0
        fi
        INIT_CONTAINERS=$(kubectl get pod -n "$NAMESPACE" "$POD" -o=jsonpath='{.spec.initContainers[*].name}')
        CONTAINERS=$(kubectl get pod -n "$NAMESPACE" "$POD" -o=jsonpath='{.spec.containers[*].name}')
        CONTAINER_LIST=$(echo -e "${INIT_CONTAINERS}\n${CONTAINERS}")
        CONTAINER_LIST=$(echo "$CONTAINER_LIST" | sed '/^$/d')
        CONTAINER=$(echo "$CONTAINER_LIST" | fzf --height=25% --border --reverse --prompt='CONTAINER > ')
          if [ -n "$CONTAINER" ]; then
          FILTER=$(echo | fzf --height=25% --border --reverse --prompt='Filter logs (optional): ' --print-query | head -n 1)
          CMD="kubectl logs -n $NAMESPACE $POD -c $CONTAINER"
          if [ -n "$FILTER" ]; then
            CMD="$CMD | grep '$FILTER'"
            echo $CMD && eval $CMD
          else
            echo $CMD && eval $CMD
          fi
        fi
        ;;
      EXEC)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        POD=$(kubectl get pod -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='POD > ' | awk '{print $1}')
        if [ -z "$POD" ]; then
          echo "No pod selected." && exit 0
        fi
        INIT_CONTAINERS=$(kubectl get pod -n "$NAMESPACE" "$POD" -o=jsonpath='{.spec.initContainers[*].name}' | tr ' ' '\n')
        CONTAINERS=$(kubectl get pod -n "$NAMESPACE" "$POD" -o=jsonpath='{.spec.containers[*].name}' | tr ' ' '\n')
        CONTAINER_LIST="$INIT_CONTAINERS"$'\n'"$CONTAINERS"
        CONTAINER=$(echo "$CONTAINER_LIST" | fzf --height=25% --border --reverse --prompt='CONTAINER > ')
        if [ -n "$CONTAINER" ]; then
          CMD_TO_EXEC=$(echo | fzf --height=25% --border --reverse --prompt='Enter command (e.g., /bin/bash): ' --print-query | head -n 1)
          CMD="kubectl exec -it -n $NAMESPACE $POD -c $CONTAINER -- $CMD_TO_EXEC"
          echo $CMD && eval $CMD
        fi
        ;;
      DELETE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SELECTED_PODS=$(kubectl get pod -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PODS > ' -m | awk '{print $1}')
        SELECTED_PODS_SPACED=$(echo "$SELECTED_PODS" | tr '\n' ' ')
        if [ -z "$SELECTED_PODS" ]; then
          echo "No pod selected." && exit 0
        else
          echo "You are about to delete the following pods:"
          echo "$SELECTED_PODS"
          CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
          if [ "$CONFIRM" = "YES" ]; then
            CMD="kubectl delete pod -n $NAMESPACE $SELECTED_PODS_SPACED --force --grace-period=0"
            echo $CMD && eval $CMD
          else
            echo "Deletion cancelled." && exit 0
          fi
        fi
        ;;
      *)
        echo "No action selected." && exit 0
        ;;
    esac
    ;;
  DEPLOYMENT)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get deployment -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get deployment -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DEPLOYMENT > ' | awk '{print $1}')
      if [ -z "$DEPLOYMENT" ]; then
        echo "No deployment selected." && exit 0
      fi
      CMD="kubectl get deployment -n $NAMESPACE $DEPLOYMENT -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DEPLOYMENT > ' | awk '{print $1}')
      if [ -z "$DEPLOYMENT" ]; then
        echo "No deployment selected." && exit 0
      fi
      CMD="kubectl describe deployment -n $NAMESPACE $DEPLOYMENT"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DEPLOYMENT > ' | awk '{print $1}')
      if [ -z "$DEPLOYMENT" ]; then
        echo "No deployment selected." && exit 0
      fi
      CMD="kubectl edit deployment -n $NAMESPACE $DEPLOYMENT"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_DEPLOYMENTS=$(kubectl get deployment -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DEPLOYMENTS > ' -m | awk '{print $1}')
      SELECTED_DEPLOYMENTS_SPACED=$(echo "$SELECTED_DEPLOYMENTS" | tr '\n' ' ')
      if [ -z "$SELECTED_DEPLOYMENTS" ]; then
        echo "No deployment selected." && exit 0
      else
        echo "You are about to delete the following deployments:"
        echo "$SELECTED_DEPLOYMENTS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete deployment -n $NAMESPACE $SELECTED_DEPLOYMENTS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  REPLICASET)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get replicaset -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get replicaset -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      REPLICASET=$(kubectl get replicaset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='REPLICASET > ' | awk '{print $1}')
      if [ -z "$REPLICASET" ]; then
        echo "No replicaset selected." && exit 0
      fi
      CMD="kubectl get replicaset -n $NAMESPACE $REPLICASET -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      REPLICASET=$(kubectl get replicaset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='REPLICASET > ' | awk '{print $1}')
      if [ -z "$REPLICASET" ]; then
        echo "No replicaset selected." && exit 0
      fi
      CMD="kubectl describe replicaset -n $NAMESPACE $REPLICASET"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      REPLICASET=$(kubectl get replicaset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='REPLICASET > ' | awk '{print $1}')
      if [ -z "$REPLICASET" ]; then
        echo "No replicaset selected." && exit 0
      fi
      CMD="kubectl edit replicaset -n $NAMESPACE $REPLICASET"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_REPLICASETS=$(kubectl get replicaset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='REPLICASETS > ' -m | awk '{print $1}')
      SELECTED_REPLICASETS_SPACED=$(echo "$SELECTED_REPLICASETS" | tr '\n' ' ')
      if [ -z "$SELECTED_REPLICASETS" ]; then
        echo "No replicaset selected." && exit 0
      else
        echo "You are about to delete the following replicasets:"
        echo "$SELECTED_REPLICASETS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete replicaset -n $NAMESPACE $SELECTED_REPLICASETS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  STATEFULSET)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get statefulset -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get statefulset -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      STATEFULSET=$(kubectl get statefulset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='STATEFULSET > ' | awk '{print $1}')
      if [ -z "$STATEFULSET" ]; then
        echo "No statefulset selected." && exit 0
      fi
      CMD="kubectl get statefulset -n $NAMESPACE $STATEFULSET -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      STATEFULSET=$(kubectl get statefulset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='STATEFULSET > ' | awk '{print $1}')
      if [ -z "$STATEFULSET" ]; then
        echo "No statefulset selected." && exit 0
      fi
      CMD="kubectl describe statefulset -n $NAMESPACE $STATEFULSET"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      STATEFULSET=$(kubectl get statefulset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='STATEFULSET > ' | awk '{print $1}')
      if [ -z "$STATEFULSET" ]; then
        echo "No statefulset selected." && exit 0
      fi
      CMD="kubectl edit statefulset -n $NAMESPACE $STATEFULSET"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_STATEFULSETS=$(kubectl get statefulset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='STATEFULSETS > ' -m | awk '{print $1}')
      SELECTED_STATEFULSETS_SPACED=$(echo "$SELECTED_STATEFULSETS" | tr '\n' ' ')
      if [ -z "$SELECTED_STATEFULSETS" ]; then
        echo "No statefulset selected." && exit 0
      else
        echo "You are about to delete the following statefulsets:"
        echo "$SELECTED_STATEFULSETS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete statefulset -n $NAMESPACE $SELECTED_STATEFULSETS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  DAEMONSET)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get daemonset -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get daemonset -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DAEMONSET=$(kubectl get daemonset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DAEMONSET > ' | awk '{print $1}')
      if [ -z "$DAEMONSET" ]; then
        echo "No daemonset selected." && exit 0
      fi
      CMD="kubectl get daemonset -n $NAMESPACE $DAEMONSET -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DAEMONSET=$(kubectl get daemonset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DAEMONSET > ' | awk '{print $1}')
      if [ -z "$DAEMONSET" ]; then
        echo "No daemonset selected." && exit 0
      fi
      CMD="kubectl describe daemonset -n $NAMESPACE $DAEMONSET"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      DAEMONSET=$(kubectl get daemonset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DAEMONSET > ' | awk '{print $1}')
      if [ -z "$DAEMONSET" ]; then
        echo "No daemonset selected." && exit 0
      fi
      CMD="kubectl edit daemonset -n $NAMESPACE $DAEMONSET"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_DAEMONSETS=$(kubectl get daemonset -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='DAEMONSETS > ' -m | awk '{print $1}')
      SELECTED_DAEMONSETS_SPACED=$(echo "$SELECTED_DAEMONSETS" | tr '\n' ' ')
      if [ -z "$SELECTED_DAEMONSETS" ]; then
        echo "No daemonset selected." && exit 0
      else
        echo "You are about to delete the following daemonsets:"
        echo "$SELECTED_DAEMONSETS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete daemonset -n $NAMESPACE $SELECTED_DAEMONSETS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  JOB)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get job -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get job -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      JOB=$(kubectl get job -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='JOB > ' | awk '{print $1}')
      if [ -z "$JOB" ]; then
        echo "No job selected." && exit 0
      fi
      CMD="kubectl get job -n $NAMESPACE $JOB -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      JOB=$(kubectl get job -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='JOB > ' | awk '{print $1}')
      if [ -z "$JOB" ]; then
        echo "No job selected." && exit 0
      fi
      CMD="kubectl describe job -n $NAMESPACE $JOB"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      JOB=$(kubectl get job -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='JOB > ' | awk '{print $1}')
      if [ -z "$JOB" ]; then
        echo "No job selected." && exit 0
      fi
      CMD="kubectl edit job -n $NAMESPACE $JOB"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_JOBS=$(kubectl get job -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='JOBS > ' -m | awk '{print $1}')
      SELECTED_JOBS_SPACED=$(echo "$SELECTED_JOBS" | tr '\n' ' ')
      if [ -z "$SELECTED_JOBS" ]; then
        echo "No job selected." && exit 0
      else
        echo "You are about to delete the following jobs:"
        echo "$SELECTED_JOBS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete job -n $NAMESPACE $SELECTED_JOBS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  CRONJOB)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get cronjob -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get cronjob -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      CRONJOB=$(kubectl get cronjob -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CRONJOB > ' | awk '{print $1}')
      if [ -z "$CRONJOB" ]; then
        echo "No cronjob selected." && exit 0
      fi
      CMD="kubectl get cronjob -n $NAMESPACE $CRONJOB -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      CRONJOB=$(kubectl get cronjob -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CRONJOB > ' | awk '{print $1}')
      if [ -z "$CRONJOB" ]; then
        echo "No cronjob selected." && exit 0
      fi
      CMD="kubectl describe cronjob -n $NAMESPACE $CRONJOB"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      CRONJOB=$(kubectl get cronjob -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CRONJOB > ' | awk '{print $1}')
      if [ -z "$CRONJOB" ]; then
        echo "No cronjob selected." && exit 0
      fi
      CMD="kubectl edit cronjob -n $NAMESPACE $CRONJOB"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_CRONJOBS=$(kubectl get cronjob -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CRONJOBS > ' -m | awk '{print $1}')
      SELECTED_CRONJOBS_SPACED=$(echo "$SELECTED_CRONJOBS" | tr '\n' ' ')
      if [ -z "$SELECTED_CRONJOBS" ]; then
        echo "No cronjob selected." && exit 0
      else
        echo "You are about to delete the following cronjobs:"
        echo "$SELECTED_CRONJOBS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete cronjob -n $NAMESPACE $SELECTED_CRONJOBS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  HORIZONTALPODAUTOSCALING)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get horizontalpodautoscaling -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get horizontalpodautoscaling -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      HORIZONTALPODAUTOSCALING=$(kubectl get horizontalpodautoscaling -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='HORIZONTALPODAUTOSCALING > ' | awk '{print $1}')
      if [ -z "$HORIZONTALPODAUTOSCALING" ]; then
        echo "No horizontalpodautoscaling selected." && exit 0
      fi
      CMD="kubectl get horizontalpodautoscaling -n $NAMESPACE $HORIZONTALPODAUTOSCALING -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      HORIZONTALPODAUTOSCALING=$(kubectl get horizontalpodautoscaling -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='HORIZONTALPODAUTOSCALING > ' | awk '{print $1}')
      if [ -z "$HORIZONTALPODAUTOSCALING" ]; then
        echo "No horizontalpodautoscaling selected." && exit 0
      fi
      CMD="kubectl describe horizontalpodautoscaling -n $NAMESPACE $HORIZONTALPODAUTOSCALING"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      HORIZONTALPODAUTOSCALING=$(kubectl get horizontalpodautoscaling -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='HORIZONTALPODAUTOSCALING > ' | awk '{print $1}')
      if [ -z "$HORIZONTALPODAUTOSCALING" ]; then
        echo "No horizontalpodautoscaling selected." && exit 0
      fi
      CMD="kubectl edit horizontalpodautoscaling -n $NAMESPACE $HORIZONTALPODAUTOSCALING"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_HORIZONTALPODAUTOSCALINGS=$(kubectl get horizontalpodautoscaling -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='HORIZONTALPODAUTOSCALINGS > ' -m | awk '{print $1}')
      SELECTED_HORIZONTALPODAUTOSCALINGS_SPACED=$(echo "$SELECTED_HORIZONTALPODAUTOSCALINGS" | tr '\n' ' ')
      if [ -z "$SELECTED_HORIZONTALPODAUTOSCALINGS" ]; then
        echo "No horizontalpodautoscaling selected." && exit 0
      else
        echo "You are about to delete the following horizontalpodautoscalings:"
        echo "$SELECTED_HORIZONTALPODAUTOSCALINGS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete horizontalpodautoscaling -n $NAMESPACE $SELECTED_HORIZONTALPODAUTOSCALINGS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  SERVICE)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nPORT_FORWARD\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
      GET)
        NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        elif [ "$NAMESPACE" = "all-namespaces" ]; then
          CMD="kubectl get service -A"
          echo $CMD && eval $CMD
        else
          CMD="kubectl get service -n $NAMESPACE"
          echo $CMD && eval $CMD
        fi
        ;;
      YAML)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SERVICE=$(kubectl get service -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICE > ' | awk '{print $1}')
        if [ -z "$SERVICE" ]; then
          echo "No service selected." && exit 0
        fi
        CMD="kubectl get service -n $NAMESPACE $SERVICE -o yaml"
        echo $CMD && eval $CMD
        ;;
      DESCRIBE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SERVICE=$(kubectl get service -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICE > ' | awk '{print $1}')
        if [ -z "$SERVICE" ]; then
          echo "No service selected." && exit 0
        fi
        CMD="kubectl describe service -n $NAMESPACE $SERVICE"
        echo $CMD && eval $CMD
        ;;
      PORT_FORWARD)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SERVICE=$(kubectl get service -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICE > ' | awk '{print $1}')
        if [ -z "$SERVICE" ]; then
          echo "No service selected." && exit 0
        fi
        PORT=$(echo | fzf --height=25% --border --reverse --prompt='Enter LOCAL and REMOTE port numbers (e.g., 5432:9999): ' --print-query | head -n 1)
        if [ -z "$PORT" ]; then
            echo "Port not specified." && exit 0
        fi
        CMD="kubectl port-forward -n $NAMESPACE service/$SERVICE $PORT"
        echo $CMD && eval $CMD
        ;;
      EDIT)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SERVICE=$(kubectl get service -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICE > ' | awk '{print $1}')
        if [ -z "$SERVICE" ]; then
          echo "No service selected." && exit 0
        fi
        CMD="kubectl edit service -n $NAMESPACE $SERVICE"
        echo $CMD && eval $CMD
        ;;
      DELETE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SELECTED_SERVICES=$(kubectl get service -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICES > ' -m | awk '{print $1}')
        SELECTED_SERVICES_SPACED=$(echo "$SELECTED_SERVICES" | tr '\n' ' ')
        if [ -z "$SELECTED_SERVICES" ]; then
          echo "No service selected." && exit 0
        else
          echo "You are about to delete the following services:"
          echo "$SELECTED_SERVICES"
          CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
          if [ "$CONFIRM" = "YES" ]; then
            CMD="kubectl delete service -n $NAMESPACE $SELECTED_SERVICES_SPACED --force --grace-period=0"
            echo $CMD && eval $CMD
          else
            echo "Deletion cancelled." && exit 0
          fi
        fi
        ;;
      *)
        echo "No action selected." && exit 0
        ;;
    esac
    ;;
  INGRESS)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
      GET)
        NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        elif [ "$NAMESPACE" = "all-namespaces" ]; then
          CMD="kubectl get ingress -A"
          echo $CMD && eval $CMD
        else
          CMD="kubectl get ingress -n $NAMESPACE"
          echo $CMD && eval $CMD
        fi
        ;;
      YAML)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        INGRESS=$(kubectl get ingress -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='INGRESS > ' | awk '{print $1}')
        if [ -z "$INGRESS" ]; then
          echo "No ingress selected." && exit 0
        fi
        CMD="kubectl get ingress -n $NAMESPACE $INGRESS -o yaml"
        echo $CMD && eval $CMD
        ;;
      DESCRIBE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        INGRESS=$(kubectl get ingress -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='NAMESPACE > INGRESS > ' | awk '{print $1}')
        if [ -z "$INGRESS" ]; then
          echo "No ingress selected." && exit 0
        fi
        CMD="kubectl describe ingress -n $NAMESPACE $INGRESS"
        echo $CMD && eval $CMD
        ;;
      EDIT)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        INGRESS=$(kubectl get ingress -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='INGRESS > ' | awk '{print $1}')
        if [ -z "$INGRESS" ]; then
          echo "No ingress selected." && exit 0
        fi
        CMD="kubectl edit ingress -n $NAMESPACE $INGRESS"
        echo $CMD && eval $CMD
        ;;
      DELETE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SELECTED_INGRESSES=$(kubectl get ingress -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='INGRESSES > ' -m | awk '{print $1}')
        SELECTED_INGRESSES_SPACED=$(echo "$SELECTED_INGRESSES" | tr '\n' ' ')
        if [ -z "$SELECTED_INGRESSES" ]; then
          echo "No ingress selected." && exit 0
        else
          echo "You are about to delete the following ingresses:"
          echo "$SELECTED_INGRESSES"
          CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
          if [ "$CONFIRM" = "YES" ]; then
            CMD="kubectl delete ingress -n $NAMESPACE $SELECTED_INGRESSES_SPACED --force --grace-period=0"
            echo $CMD && eval $CMD
          else
            echo "Deletion cancelled." && exit 0
          fi
        fi
        ;;
      *)
        echo "No action selected." && exit 0
        ;;
    esac
    ;;
  CONFIGMAP)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
      GET)
        NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        elif [ "$NAMESPACE" = "all-namespaces" ]; then
          CMD="kubectl get configmap -A"
          echo $CMD && eval $CMD
        else
          CMD="kubectl get configmap -n $NAMESPACE"
          echo $CMD && eval $CMD
        fi
        ;;
      YAML)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        CONFIGMAP=$(kubectl get configmap -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CONFIGMAP > ' | awk '{print $1}')
        if [ -z "$CONFIGMAP" ]; then
          echo "No configmap selected." && exit 0
        fi
        CMD="kubectl get configmap -n $NAMESPACE $CONFIGMAP -o yaml"
        echo $CMD && eval $CMD
        ;;
      DESCRIBE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        CONFIGMAP=$(kubectl get configmap -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CONFIGMAP > ' | awk '{print $1}')
        if [ -z "$CONFIGMAP" ]; then
          echo "No configmap selected." && exit 0
        fi
        CMD="kubectl describe configmap -n $NAMESPACE $CONFIGMAP"
        echo $CMD && eval $CMD
        ;;
      EDIT)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        CONFIGMAP=$(kubectl get configmap -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CONFIGMAP > ' | awk '{print $1}')
        if [ -z "$CONFIGMAP" ]; then
          echo "No configmap selected." && exit 0
        fi
        CMD="kubectl edit configmap -n $NAMESPACE $CONFIGMAP"
        echo $CMD && eval $CMD
        ;;
      DELETE)
        NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
        if [ -z "$NAMESPACE" ]; then
          echo "No namespace selected." && exit 0
        fi
        SELECTED_CONFIGMAPS=$(kubectl get configmap -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='CONFIGMAPS > ' -m | awk '{print $1}')
        SELECTED_CONFIGMAPS_SPACED=$(echo "$SELECTED_CONFIGMAPS" | tr '\n' ' ')
        if [ -z "$SELECTED_CONFIGMAPS" ]; then
          echo "No configmap selected." && exit 0
        else
          echo "You are about to delete the following configmaps:"
          echo "$SELECTED_CONFIGMAPS"
          CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
          if [ "$CONFIRM" = "YES" ]; then
            CMD="kubectl delete configmap -n $NAMESPACE $SELECTED_CONFIGMAPS_SPACED --force --grace-period=0"
            echo $CMD && eval $CMD
          else
            echo "Deletion cancelled." && exit 0
          fi
        fi
        ;;
      *)
        echo "No action selected." && exit 0
        ;;
    esac
    ;;
  SECRET)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get secret -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get secret -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SECRET=$(kubectl get secret -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SECRET > ' | awk '{print $1}')
      if [ -z "$SECRET" ]; then
        echo "No secret selected." && exit 0
      fi
      CMD="kubectl get secret -n $NAMESPACE $SECRET -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SECRET=$(kubectl get secret -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SECRET > ' | awk '{print $1}')
      if [ -z "$SECRET" ]; then
        echo "No secret selected." && exit 0
      fi
      CMD="kubectl describe secret -n $NAMESPACE $SECRET"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SECRET=$(kubectl get secret -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SECRET > ' | awk '{print $1}')
      if [ -z "$SECRET" ]; then
        echo "No secret selected." && exit 0
      fi
      CMD="kubectl edit secret -n $NAMESPACE $SECRET"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_SECRETS=$(kubectl get secret -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SECRETS > ' -m | awk '{print $1}')
      SELECTED_SECRETS_SPACED=$(echo "$SELECTED_SECRETS" | tr '\n' ' ')
      if [ -z "$SELECTED_SECRETS" ]; then
        echo "No secret selected." && exit 0
      else
        echo "You are about to delete the following secrets:"
        echo "$SELECTED_SECRETS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete secret -n $NAMESPACE $SELECTED_SECRETS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  PERSISTENTVOLUMECLAIM)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get persistentvolumeclaim -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get persistentvolumeclaim -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUMECLAIM=$(kubectl get persistentvolumeclaim -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUMECLAIM > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUMECLAIM" ]; then
        echo "No persistentvolumeclaim selected." && exit 0
      fi
      CMD="kubectl get persistentvolumeclaim -n $NAMESPACE $PERSISTENTVOLUMECLAIM -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUMECLAIM=$(kubectl get persistentvolumeclaim -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUMECLAIM > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUMECLAIM" ]; then
        echo "No persistentvolumeclaim selected." && exit 0
      fi
      CMD="kubectl describe persistentvolumeclaim -n $NAMESPACE $PERSISTENTVOLUMECLAIM"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUMECLAIM=$(kubectl get persistentvolumeclaim -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUMECLAIM > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUMECLAIM" ]; then
        echo "No persistentvolumeclaim selected." && exit 0
      fi
      CMD="kubectl edit persistentvolumeclaim -n $NAMESPACE $PERSISTENTVOLUMECLAIM"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_PERSISTENTVOLUMECLAIMS=$(kubectl get persistentvolumeclaim -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUMECLAIMS > ' -m | awk '{print $1}')
      SELECTED_PERSISTENTVOLUMECLAIMS_SPACED=$(echo "$SELECTED_PERSISTENTVOLUMECLAIMS" | tr '\n' ' ')
      if [ -z "$SELECTED_PERSISTENTVOLUMECLAIMS" ]; then
        echo "No persistentvolumeclaim selected." && exit 0
      else
        echo "You are about to delete the following persistentvolumeclaims:"
        echo "$SELECTED_PERSISTENTVOLUMECLAIMS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete persistentvolumeclaim -n $NAMESPACE $SELECTED_PERSISTENTVOLUMECLAIMS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  PERSISTENTVOLUME)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get persistentvolume -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get persistentvolume -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUME=$(kubectl get persistentvolume -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUME > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUME" ]; then
        echo "No persistentvolume selected." && exit 0
      fi
      CMD="kubectl get persistentvolume -n $NAMESPACE $PERSISTENTVOLUME -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUME=$(kubectl get persistentvolume -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUME > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUME" ]; then
        echo "No persistentvolume selected." && exit 0
      fi
      CMD="kubectl describe persistentvolume -n $NAMESPACE $PERSISTENTVOLUME"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      PERSISTENTVOLUME=$(kubectl get persistentvolume -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUME > ' | awk '{print $1}')
      if [ -z "$PERSISTENTVOLUME" ]; then
        echo "No persistentvolume selected." && exit 0
      fi
      CMD="kubectl edit persistentvolume -n $NAMESPACE $PERSISTENTVOLUME"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_PERSISTENTVOLUMES=$(kubectl get persistentvolume -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='PERSISTENTVOLUMES > ' -m | awk '{print $1}')
      SELECTED_PERSISTENTVOLUMES_SPACED=$(echo "$SELECTED_PERSISTENTVOLUMES" | tr '\n' ' ')
      if [ -z "$SELECTED_PERSISTENTVOLUMES" ]; then
        echo "No persistentvolume selected." && exit 0
      else
        echo "You are about to delete the following persistentvolumes:"
        echo "$SELECTED_PERSISTENTVOLUMES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete persistentvolume -n $NAMESPACE $SELECTED_PERSISTENTVOLUMES_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  SERVICEACCOUNT)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get serviceaccount -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get serviceaccount -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SERVICEACCOUNT=$(kubectl get serviceaccount -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICEACCOUNT > ' | awk '{print $1}')
      if [ -z "$SERVICEACCOUNT" ]; then
        echo "No serviceaccount selected." && exit 0
      fi
      CMD="kubectl get serviceaccount -n $NAMESPACE $SERVICEACCOUNT -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SERVICEACCOUNT=$(kubectl get serviceaccount -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICEACCOUNT > ' | awk '{print $1}')
      if [ -z "$SERVICEACCOUNT" ]; then
        echo "No serviceaccount selected." && exit 0
      fi
      CMD="kubectl describe serviceaccount -n $NAMESPACE $SERVICEACCOUNT"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SERVICEACCOUNT=$(kubectl get serviceaccount -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICEACCOUNT > ' | awk '{print $1}')
      if [ -z "$SERVICEACCOUNT" ]; then
        echo "No serviceaccount selected." && exit 0
      fi
      CMD="kubectl edit serviceaccount -n $NAMESPACE $SERVICEACCOUNT"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_SERVICEACCOUNTS=$(kubectl get serviceaccount -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='SERVICEACCOUNTS > ' -m | awk '{print $1}')
      SELECTED_SERVICEACCOUNTS_SPACED=$(echo "$SELECTED_SERVICEACCOUNTS" | tr '\n' ' ')
      if [ -z "$SELECTED_SERVICEACCOUNTS" ]; then
        echo "No serviceaccount selected." && exit 0
      else
        echo "You are about to delete the following serviceaccounts:"
        echo "$SELECTED_SERVICEACCOUNTS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete serviceaccount -n $NAMESPACE $SELECTED_SERVICEACCOUNTS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  ROLE)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get role -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get role -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLE=$(kubectl get role -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLE > ' | awk '{print $1}')
      if [ -z "$ROLE" ]; then
        echo "No role selected." && exit 0
      fi
      CMD="kubectl get role -n $NAMESPACE $ROLE -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLE=$(kubectl get role -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLE > ' | awk '{print $1}')
      if [ -z "$ROLE" ]; then
        echo "No role selected." && exit 0
      fi
      CMD="kubectl describe role -n $NAMESPACE $ROLE"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLE=$(kubectl get role -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLE > ' | awk '{print $1}')
      if [ -z "$ROLE" ]; then
        echo "No role selected." && exit 0
      fi
      CMD="kubectl edit role -n $NAMESPACE $ROLE"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_ROLES=$(kubectl get role -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLES > ' -m | awk '{print $1}')
      SELECTED_ROLES_SPACED=$(echo "$SELECTED_ROLES" | tr '\n' ' ')
      if [ -z "$SELECTED_ROLES" ]; then
        echo "No role selected." && exit 0
      else
        echo "You are about to delete the following roles:"
        echo "$SELECTED_ROLES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete role -n $NAMESPACE $SELECTED_ROLES_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  ROLEBINDING)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      NAMESPACE=$( (echo "all-namespaces" && kubectl get ns --no-headers | awk '{print $1}' | sort) | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      elif [ "$NAMESPACE" = "all-namespaces" ]; then
        CMD="kubectl get rolebinding -A"
        echo $CMD && eval $CMD
      else
        CMD="kubectl get rolebinding -n $NAMESPACE"
        echo $CMD && eval $CMD
      fi
      ;;
    YAML)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLEBINDING=$(kubectl get rolebinding -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLEBINDING > ' | awk '{print $1}')
      if [ -z "$ROLEBINDING" ]; then
        echo "No rolebinding selected." && exit 0
      fi
      CMD="kubectl get rolebinding -n $NAMESPACE $ROLEBINDING -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLEBINDING=$(kubectl get rolebinding -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLEBINDING > ' | awk '{print $1}')
      if [ -z "$ROLEBINDING" ]; then
        echo "No rolebinding selected." && exit 0
      fi
      CMD="kubectl describe rolebinding -n $NAMESPACE $ROLEBINDING"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      ROLEBINDING=$(kubectl get rolebinding -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLEBINDING > ' | awk '{print $1}')
      if [ -z "$ROLEBINDING" ]; then
        echo "No rolebinding selected." && exit 0
      fi
      CMD="kubectl edit rolebinding -n $NAMESPACE $ROLEBINDING"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      NAMESPACE=$(kubectl get ns --no-headers | awk '{print $1}' | sort | fzf --height=25% --border --reverse --prompt='NAMESPACE > ')
      if [ -z "$NAMESPACE" ]; then
        echo "No namespace selected." && exit 0
      fi
      SELECTED_ROLEBINDINGS=$(kubectl get rolebinding -n "$NAMESPACE" --no-headers | fzf --height=25% --border --reverse --prompt='ROLEBINDINGS > ' -m | awk '{print $1}')
      SELECTED_ROLEBINDINGS_SPACED=$(echo "$SELECTED_ROLEBINDINGS" | tr '\n' ' ')
      if [ -z "$SELECTED_ROLEBINDINGS" ]; then
        echo "No rolebinding selected." && exit 0
      else
        echo "You are about to delete the following rolebindings:"
        echo "$SELECTED_ROLEBINDINGS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete rolebinding -n $NAMESPACE $SELECTED_ROLEBINDINGS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  CLUSTERROLE)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      CMD="kubectl get clusterrole"
      echo $CMD && eval $CMD
      ;;
    YAML)
      CLUSTERROLE=$(kubectl get clusterrole --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLE > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLE" ]; then
        echo "No clusterrole selected." && exit 0
      fi
      CMD="kubectl get clusterrole $CLUSTERROLE -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      CLUSTERROLE=$(kubectl get clusterrole --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLE > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLE" ]; then
        echo "No clusterrole selected." && exit 0
      fi
      CMD="kubectl describe clusterrole $CLUSTERROLE"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      CLUSTERROLE=$(kubectl get clusterrole --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLE > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLE" ]; then
        echo "No clusterrole selected." && exit 0
      fi
      CMD="kubectl edit clusterrole $CLUSTERROLE"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      SELECTED_CLUSTERROLES=$(kubectl get clusterrole --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLES > ' -m | awk '{print $1}')
      SELECTED_CLUSTERROLES_SPACED=$(echo "$SELECTED_CLUSTERROLES" | tr '\n' ' ')
      if [ -z "$SELECTED_CLUSTERROLES" ]; then
        echo "No clusterrole selected." && exit 0
      else
        echo "You are about to delete the following clusterroles:"
        echo "$SELECTED_CLUSTERROLES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete clusterrole $SELECTED_CLUSTERROLES_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  CLUSTERROLEBINDING)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      CMD="kubectl get clusterrolebinding"
      echo $CMD && eval $CMD
      ;;
    YAML)
      CLUSTERROLEBINDING=$(kubectl get clusterrolebinding --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLEBINDING > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLEBINDING" ]; then
        echo "No clusterrolebinding selected." && exit 0
      fi
      CMD="kubectl get clusterrolebinding $CLUSTERROLEBINDING -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      CLUSTERROLEBINDING=$(kubectl get clusterrolebinding --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLEBINDING > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLEBINDING" ]; then
        echo "No clusterrolebinding selected." && exit 0
      fi
      CMD="kubectl describe clusterrolebinding $CLUSTERROLEBINDING"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      CLUSTERROLEBINDING=$(kubectl get clusterrolebinding --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLEBINDING > ' | awk '{print $1}')
      if [ -z "$CLUSTERROLEBINDING" ]; then
        echo "No clusterrolebinding selected." && exit 0
      fi
      CMD="kubectl edit clusterrolebinding $CLUSTERROLEBINDING"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      SELECTED_CLUSTERROLEBINDINGS=$(kubectl get clusterrolebinding --no-headers | fzf --height=25% --border --reverse --prompt='CLUSTERROLEBINDINGS > ' -m | awk '{print $1}')
      SELECTED_CLUSTERROLEBINDINGS_SPACED=$(echo "$SELECTED_CLUSTERROLEBINDINGS" | tr '\n' ' ')
      if [ -z "$SELECTED_CLUSTERROLEBINDINGS" ]; then
        echo "No clusterrolebinding selected." && exit 0
      else
        echo "You are about to delete the following clusterrolebindings:"
        echo "$SELECTED_CLUSTERROLEBINDINGS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete clusterrolebinding $SELECTED_CLUSTERROLEBINDINGS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  CUSTOMRESOURCEDEFINITION)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      CMD="kubectl get customresourcedefinition"
      echo $CMD && eval $CMD
      ;;
    YAML)
      CUSTOMRESOURCEDEFINITION=$(kubectl get customresourcedefinition --no-headers | fzf --height=25% --border --reverse --prompt='CUSTOMRESOURCEDEFINITION > ' | awk '{print $1}')
      if [ -z "$CUSTOMRESOURCEDEFINITION" ]; then
        echo "No customresourcedefinition selected." && exit 0
      fi
      CMD="kubectl get customresourcedefinition $CUSTOMRESOURCEDEFINITION -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      CUSTOMRESOURCEDEFINITION=$(kubectl get customresourcedefinition --no-headers | fzf --height=25% --border --reverse --prompt='CUSTOMRESOURCEDEFINITION > ' | awk '{print $1}')
      if [ -z "$CUSTOMRESOURCEDEFINITION" ]; then
        echo "No customresourcedefinition selected." && exit 0
      fi
      CMD="kubectl describe customresourcedefinition $CUSTOMRESOURCEDEFINITION"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      CUSTOMRESOURCEDEFINITION=$(kubectl get customresourcedefinition --no-headers | fzf --height=25% --border --reverse --prompt='CUSTOMRESOURCEDEFINITION > ' | awk '{print $1}')
      if [ -z "$CUSTOMRESOURCEDEFINITION" ]; then
        echo "No customresourcedefinition selected." && exit 0
      fi
      CMD="kubectl edit customresourcedefinition $CUSTOMRESOURCEDEFINITION"
      echo $CMD && eval $CMD
      ;;
    DELETE)
      SELECTED_CUSTOMRESOURCEDEFINITIONS=$(kubectl get customresourcedefinition --no-headers | fzf --height=25% --border --reverse --prompt='CUSTOMRESOURCEDEFINITIONS > ' -m | awk '{print $1}')
      SELECTED_CUSTOMRESOURCEDEFINITIONS_SPACED=$(echo "$SELECTED_CUSTOMRESOURCEDEFINITIONS" | tr '\n' ' ')
      if [ -z "$SELECTED_CUSTOMRESOURCEDEFINITIONS" ]; then
        echo "No customresourcedefinition selected." && exit 0
      else
        echo "You are about to delete the following customresourcedefinitions:"
        echo "$SELECTED_CUSTOMRESOURCEDEFINITIONS"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete customresourcedefinition $SELECTED_CUSTOMRESOURCEDEFINITIONS_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  NODE)
    ACTION=$(echo -e "GET\nYAML\nDESCRIBE\nEDIT\nCORDON\nUNCORDON\nDELETE" | fzf --height=25% --border --reverse --prompt='ACTION > ')
    case $ACTION in
    GET)
      CMD="kubectl get node"
      echo $CMD && eval $CMD
      ;;
    YAML)
      NODE=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODE > ' | awk '{print $1}')
      if [ -z "$NODE" ]; then
        echo "No node selected." && exit 0
      fi
      CMD="kubectl get node $NODE -o yaml"
      echo $CMD && eval $CMD
      ;;
    DESCRIBE)
      NODE=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODE > ' | awk '{print $1}')
      if [ -z "$NODE" ]; then
        echo "No node selected." && exit 0
      fi
      CMD="kubectl describe node $NODE"
      echo $CMD && eval $CMD
      ;;
    EDIT)
      NODE=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODE > ' | awk '{print $1}')
      if [ -z "$NODE" ]; then
        echo "No node selected." && exit 0
      fi
      CMD="kubectl edit node $NODE"
      echo $CMD && eval $CMD
      ;;
    CORDON)
      SELECTED_NODES=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODES > ' -m | awk '{print $1}')
      SELECTED_NODES_SPACED=$(echo "$SELECTED_NODES" | tr '\n' ' ')
      if [ -z "$SELECTED_NODES" ]; then
        echo "No node selected." && exit 0
      else
        echo "You are about to cordon the following nodes:"
        echo "$SELECTED_NODES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl cordon $SELECTED_NODES_SPACED"
          echo $CMD && eval $CMD
        else
          echo "Cordon cancelled." && exit 0
        fi
      fi
      ;;
    UNCORDON)
      SELECTED_NODES=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODES > ' -m | awk '{print $1}')
      SELECTED_NODES_SPACED=$(echo "$SELECTED_NODES" | tr '\n' ' ')
      if [ -z "$SELECTED_NODES" ]; then
        echo "No node selected." && exit 0
      else
        echo "You are about to uncordon the following nodes:"
        echo "$SELECTED_NODES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl uncordon $SELECTED_NODES_SPACED"
          echo $CMD && eval $CMD
        else
          echo "Uncordon cancelled." && exit 0
        fi
      fi
      ;;
    DELETE)
      SELECTED_NODES=$(kubectl get node --no-headers | fzf --height=25% --border --reverse --prompt='NODES > ' -m | awk '{print $1}')
      SELECTED_NODES_SPACED=$(echo "$SELECTED_NODES" | tr '\n' ' ')
      if [ -z "$SELECTED_NODES" ]; then
        echo "No node selected." && exit 0
      else
        echo "You are about to delete the following nodes:"
        echo "$SELECTED_NODES"
        CONFIRM=$(echo -e "NO\nYES" | fzf --height=25% --border --reverse --prompt='Are you sure? (y/N) > ')
        if [ "$CONFIRM" = "YES" ]; then
          CMD="kubectl delete node $SELECTED_NODES_SPACED --force --grace-period=0"
          echo $CMD && eval $CMD
        else
          echo "Deletion cancelled." && exit 0
        fi
      fi
      ;;
    *)
      echo "No action selected." && exit 0
      ;;
    esac
    ;;
  *)
    echo "No resource selected." && exit 0
    ;;
esac