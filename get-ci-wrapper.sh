#!/usr/bin/env bash

CI_WRAPPERS_HOME="${CI_WRAPPERS_HOME:-${HOME}/.ci-wrappers}"

_create_config() (
  # Create or update default config file
  mkdir -p "${CI_WRAPPERS_HOME}"
  cat >"${CI_WRAPPERS_HOME}/config" <<END
CI_VAGRANT_VERSION=2.3.4
CI_TERRAFORM_VERSION=1.3.6
CI_DOCKER_CLIENT_VERSION=20.10.19
CI_DOCKER_COMPOSE_VERSION=2.13.0
CI_GH_CLI_VERSION=2.20.2

CI_MAVEN_DEFAULT_IMAGE="\${CI_MAVEN_DEFAULT_IMAGE:-brunoe/maven:3.8.6-eclipse-temurin-17}"
CI_JAVA_DEFAULT_ARCHETYPE_GROUPID="\${CI_JAVA_DEFAULT_ARCHETYPE_GROUPID:-fr.univtln.bruno.demos.archetypes}"
CI_JAVA_DEFAULT_ARCHETYPE_ARTIFACTID="\${CI_JAVA_DEFAULT_ARCHETYPE_ARTIFACTID:-demomavenarchetype}"
CI_JAVA_DEFAULT_ARCHETYPE_VERSION="\${CI_JAVA_DEFAULT_ARCHETYPE_VERSION:-1.1-SNAPSHOT}"

export CI_WRAPPERS_HOME="\${CI_WRAPPERS_HOME:-\${HOME}/.ci-wrappers}"
export DOCKER_CONFIG="\$CI_WRAPPERS_HOME/.docker"
END
)

# Creates a default config files.
echo "Creates a default config files."
_create_config

# Load the config
source "${CI_WRAPPERS_HOME}/config"

# Installs the script locally
echo "Installs the scripts"
curl -s https://raw.githubusercontent.com/ebpro/ciwrappers/develop/ci-wrappers.sh > "$CI_WRAPPERS_HOME"/ci-wrappers.sh

printf "\nto activate :\n\t source $CI_WRAPPERS_HOME/ci-wrappers.sh\n\n"
printf "or add to .zshrc or .bashrc : \n\texport CI_WRAPPERS_HOME=${CI_WRAPPERS_HOME} [[ -f \"\${CI_WRAPPERS_HOME}/ci-wrappers.sh\" ]] && source \"\${CI_WRAPPERS_HOME}/ci-wrappers.sh"
