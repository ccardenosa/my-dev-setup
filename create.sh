#!/bin/bash

function setup-env {
  ansible-playbook -i playbooks/inventory.ini playbooks/setup-dev-env.yaml -vvv
}

function get-repos {
  ansible-playbook -i playbooks/inventory.ini playbooks/get-repos.yaml -vvv
}

setup-env
get-repos
