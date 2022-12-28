#!/bin/bash

function add_etc_entry {
  pod_name=$1
  ip=$2
  hostname=$3
  cmd="echo '${ip} ${hostname}' >> /etc/hosts"
  echo "Updating ${pod_name} running... ${cmd}"
  podman exec -it ${pod_name} bash -c "${cmd}"
}

function update_etc_files {

  kd="kind 2>/dev/null"

  get_nodes_cmd="${kd} get nodes|grep control-plane|head -1"
  while sleep 1; do
    [[ "$(eval ${get_nodes_cmd})" != "" ]] && break
    echo "Waiting for control-plane..."
  done

  control_plane=$(eval ${get_nodes_cmd})
  echo "Waiting for control-plane IP..."
  get_ip_cmd="podman inspect $control_plane -f {{.NetworkSettings.Networks.kind.IPAddress}}"
  while sleep 1; do
    [[ "$(eval $get_ip_cmd)" != "" ]] && break
  done

  control_plane_ip=$(eval $get_ip_cmd)

  #registry_name="kind-registry"
  #registry_ip=$(eval "podman inspect ${registry_name} -f {{.NetworkSettings.Networks.kind.IPAddress}}")

  #add_etc_entry ${control_plane} ${registry_ip} ${registry_name}

  workers=( $(eval "${kd} get nodes|grep worker") )
  echo "Iterating over: ${workers[@]}..."
  for h in ${workers[@]}; do
    #add_etc_entry $h ${registry_ip} ${registry_name}
    add_etc_entry $h ${control_plane_ip} ${control_plane}
  done

  while sleep 5; do
    if [[ $(kubectl 2>/dev/null get node) != "" ]]; then
      ${kind} export kubeconfig
      kubectl cluster-info --context kind-kind
      break
    fi
  done
}

function wait_for_pod {
  ns=$1
  select=$2
  kubectl -n ${ns} wait pod -l ${select} --for=condition=PodScheduled
  #kubectl -n ${ns} wait pod -l ${select} --for=condition=Ready
}

function add_docker_creds {
  ns=$1
  secret_name=$2
  server=$3
  service_account=$4

  creds=$(cat $XDG_RUNTIME_DIR/containers/auth.json | jq -r '.auths."'${server}'".auth'|base64 -d)
  user=$(echo ${creds} | awk -F':' '{print $1}')
  pass=$(echo ${creds} | awk -F':' '{print $2}')
  kubectl -n ${ns} create secret docker-registry ${secret_name} --docker-server=${server} --docker-username=${user} --docker-password=${pass} --docker-email=ccardeno@redhat.com
  kubectl -n ${ns} patch serviceaccount ${service_account} -p "{\"imagePullSecrets\": [{\"name\": \"${secret_name}\"}]}"
}

update_etc_files
#sleep 60
#wait_for_pod "kube-system" "name=cni-plugins"
#add_docker_creds "kube-system" "kind-registry-secret" "index.docker.io" "$(kubectl -n kube-system get po -l name=cni-plugins -ojsonpath='{.items[0].spec.serviceAccountName}')"
#add_docker_creds "kube-system" "kind-registry-secret" "index.docker.io" "default"
