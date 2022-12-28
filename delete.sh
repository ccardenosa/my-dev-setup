#!/bin/bash

function delete-repos {
  ansible-playbook -i playbooks/inventory.ini playbooks/get-repos.yaml --tags clean-up -vvv
}

delete-repos
