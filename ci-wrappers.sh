#!/usr/bin/env bash

_B_TITLE='\033[0;33m'
_E_TITLE='\033[0;0m'

_create_config() (
  # Create or update default config file
  mkdir -p "${HOME}/.ci-wrappers/"
  cat >!"${HOME}/.ci-wrappers/config" <<END
CI_VAGRANT_VERSION=2.3.4
CI_TERRAFORM_VERSION=1.3.6
CI_DOCKER_CLIENT_VERSION=20.10.19
CI_DOCKER_COMPOSE_VERSION=2.13.0
CI_GH_CLI_VERSION=2.20.2

CI_MAVEN_DEFAULT_IMAGE="brunoe/maven:3.8.6-eclipse-temurin-17"
CI_JAVA_DEFAULT_ARCHETYPE_GROUPID="fr.univtln.bruno.demos.archetypes"
CI_JAVA_DEFAULT_ARCHETYPE_ARTIFACTID="demomavenarchetype"
CI_JAVA_DEFAULT_ARCHETYPE_VERSION="1.1-SNAPSHOT"

export CI_WRAPPERS_HOME="\${CI_WRAPPERS_HOME:-\${HOME}/.ci-wrappers}"
export DOCKER_CONFIG="\$CI_WRAPPERS_HOME/.docker"
END
)

_create_config

_init() {
  _create_config
  source "${HOME}/.ci-wrappers/config"
}

ci-wrappers-usage() {
  printf 'install-dockerclient-vagrant-terraform\n\t installs a docker client, vagant and terraform in %s/bin\n'"${HOME}"
  printf "new-java-project [projectname]\n\t create a new java+maven project ready for CI\n"
  echo "docker-wrapper"
  echo "docker-wrapper-build"
  echo "docker-wrapper-build-all"
  echo "docker-wrapper-run-all"
  echo "docker-mvn"
  echo "docker-sonar-analysis"
}

install-ci-software() {
  _init

  if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi
  mkdir -p "${CI_WRAPPERS_HOME}"/bin
  #Ensure that tools are in PATH
  [[ ":$PATH:" != *":${CI_WRAPPERS_HOME}/bin:"* ]] && PATH="${CI_WRAPPERS_HOME}/bin:${PATH}"

  _version_gh() ("${CI_WRAPPERS_HOME}"/bin/gh --version | head -n 1 | cut -d ' ' -f 3)
  if [ ! -f "${CI_WRAPPERS_HOME}"/bin/gh ] || [ "$(_version_gh)" != "${CI_GH_CLI_VERSION}" ]; then
    echo "Installing gh client ${CI_GH_CLI_VERSION}" &&
      curl -sL "https://github.com/cli/cli/releases/download/v${CI_GH_CLI_VERSION}/gh_${CI_GH_CLI_VERSION}_linux_amd64.tar.gz" |
      tar --directory="${CI_WRAPPERS_HOME}/bin/" --strip-components=2 -zx "gh_${CI_GH_CLI_VERSION}_linux_amd64/bin/gh" &&
      chmod +x "${CI_WRAPPERS_HOME}/bin/gh"
  else
    echo "GitHub CLI already installed : $(_version_gh)"
  fi

  _version_docker() ("${CI_WRAPPERS_HOME}"/bin/docker --version | cut -d " " -f 3 | tr -d ',')
  if [ ! -f "${CI_WRAPPERS_HOME}"/bin/docker ] || [ "$(_version_docker)" != "${CI_DOCKER_CLIENT_VERSION}" ]; then
    echo "Installing docker client ${CI_DOCKER_CLIENT_VERSION}"
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${CI_DOCKER_CLIENT_VERSION}.tgz" |
      tar --directory="${CI_WRAPPERS_HOME}/bin/" --strip-components=1 -zx docker/docker &&
      chmod +x "${CI_WRAPPERS_HOME}/bin/docker"
  else
    echo "docker client already installed $(_version_docker)"
  fi
  _version_dockercompose() ("${DOCKER_CONFIG}"/cli-plugins/docker-compose --version | sed 's/^[^0-9]*\([0-9][0-9\.]*\)[^0-9]*$/\1/g')
  if [ ! -f "${CI_WRAPPERS_HOME}"/.docker/cli-plugins/docker-compose ] || [ "$(_version_dockercompose)" != "${CI_DOCKER_COMPOSE_VERSION}" ]; then
    echo "Installing docker compose plugin ${CI_DOCKER_COMPOSE_VERSION}"
    mkdir -p "${CI_WRAPPERS_HOME}"/.docker/cli-plugins/ &&
      curl -sL "https://github.com/docker/compose/releases/download/v${CI_DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        -o "${DOCKER_CONFIG}"/cli-plugins/docker-compose &&
      chmod +x "${DOCKER_CONFIG}"/cli-plugins/docker-compose
  else
    echo "Docker compose plugin already installed $(_version_dockercompose)"
  fi

  _version_vagrant() ("${CI_WRAPPERS_HOME}"/bin/vagrant --version | sed 's/^[^0-9]*\([0-9][0-9\.]*\)[^0-9]*$/\1/g')
  if [ ! -f "${CI_WRAPPERS_HOME}"/bin/vagrant ] || [ "$(_version_vagrant)" != "${CI_VAGRANT_VERSION}" ]; then
    echo "Installing vagrant ${CI_VAGRANT_VERSION}"
    curl -sL "https://releases.hashicorp.com/vagrant/${CI_VAGRANT_VERSION}/vagrant_${CI_VAGRANT_VERSION}_linux_amd64.zip" |
      gunzip - >"${CI_WRAPPERS_HOME}/bin/vagrant" &&
      chmod +x "${CI_WRAPPERS_HOME}/bin/vagrant"
  else
    echo "Vagrant already installed $(_version_vagrant)"
  fi

  _version_terraform() ("${CI_WRAPPERS_HOME}"/bin/terraform --version | head -n 1 | sed 's/^[^0-9]*\([0-9][0-9\.]*\)[^0-9]*$/\1/g')
  if [ ! -f "${CI_WRAPPERS_HOME}"/bin/terraform ] || [ "$(_version_terraform)" != "${CI_TERRAFORM_VERSION}" ]; then
    echo "Installing terraform ${CI_TERRAFORM_VERSION}"
    curl -sL "https://releases.hashicorp.com/terraform/${CI_TERRAFORM_VERSION}/terraform_${CI_TERRAFORM_VERSION}_linux_amd64.zip" |
      gunzip - >"${CI_WRAPPERS_HOME}/bin/terraform" &&
      chmod +x "${CI_WRAPPERS_HOME}"/bin/terraform
  else
    echo "Terraform already installed $(_version_terraform)"
  fi
}

provision-docker-engine() {
  _check_variables VAGRANT_HTTP_PROXY VAGRANT_HTTPS_PROXY VAGRANT_NO_PROXY
}

_moveVBoxDefaultFolder() {
  targetDirectory=${1:-/scratch/${USER}}
  VBoxManage list systemproperties | grep "Current default machine folder:" &&
    mkdir -p "${targetDirectory}" &&
    vboxmanage setproperty machinefolder "${targetDirectory}"/VirtualBox\ VMs &&
    echo -n "New " && VBoxManage list systemproperties | grep "Default machine folder:"
}

_check_needed_variables() {
  _check_variables GITHUBLOGIN GITHUBTOKEN GITHUB_ORG SONAR_URL SONAR_TOKEN
}

_check_variables() {
  if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi
  for varname in "$@"; do
    v="${!varname}"
    if [ ! -n "${v-unset}" ]; then
      echo "$varname is not set: exiting"
      exit 1
    fi
  done
}

# This utility function computes the image name and tag from the project directory and the git branch.
_docker_env() {
  DOCKER_REPO_NAME=${GITHUB_ORG}
  IMAGE_NAME=$(echo "${PWD##*/}" | tr '[:upper:]' '[:lower:]')
  IMAGE_TAG=$(git rev-parse --abbrev-ref HEAD)
  DOCKER_TARGET=${DOCKER_TARGET:-finalJLinkAlpine}
  DOCKER_FULL_IMAGE_NAME="$DOCKER_REPO_NAME/$IMAGE_NAME:$IMAGE_TAG-$DOCKER_TARGET"
}

# This utility function look for final target in the docker file and compute docker image name and tag (oen by line).
_docker-wrapper-all-images() (
  for finalTarget in $(grep -E 'FROM.*final.*' docker/Dockerfile | tr -s ' ' | cut -f 4 -d ' '); do
    DOCKER_TARGET="$finalTarget" _docker_env
    echo "$finalTarget#${DOCKER_FULL_IMAGE_NAME}"
  done
)

# This function is a wrapper around the docker command to passes the env (credentials, image names, ...)
docker-wrapper() (
  _docker_env
  DOCKER_BUILDKIT=1 \
    docker "$1" \
    --file docker/Dockerfile \
    --build-arg IMAGE_NAME="$IMAGE_NAME" \
    --build-arg DOCKER_USERNAME="$DOCKER_USERNAME" \
    --build-arg DOCKER_PASSWORD="$DOCKER_PASSWORD" \
    --build-arg SONAR_TOKEN="$SONAR_TOKEN" \
    --build-arg SONAR_URL="$SONAR_URL" \
    --build-arg GITHUB_LOGIN="$GITHUB_LOGIN" \
    --build-arg GITHUB_TOKEN="$GITHUB_TOKEN" \
    --target "${DOCKER_TARGET}" \
    -t "${DOCKER_FULL_IMAGE_NAME}" \
    "${@: -1}"
)

# Build a target image ($DOCKER_TARGET)
docker-wrapper-build() (
  docker-wrapper build "$@" .
)

# Builds images for final targets of the Dockerfile
docker-wrapper-build-all() (
  for image in $(_docker-wrapper-all-images); do
    finalTarget=$(echo "$image" | cut -f1 -d '#' -)
    DOCKER_TARGET="$finalTarget" docker-wrapper-build "$@"
  done
  for image in $(_docker-wrapper-all-images); do
    imageName=$(echo "$image" | cut -f2 -d '#' -)
    docker image ls "$imageName" | tail -n+2
  done
)

# Runs a target image ($DOCKER_TARGET)
docker-wrapper-run() (
  _docker_env
  echo "Running ${DOCKER_FULL_IMAGE_NAME}"
  docker run --rm -it "${DOCKER_FULL_IMAGE_NAME}"
)

#Runs all the final targets
docker-wrapper-run-all() (
  for image in $(_docker-wrapper-all-images); do
    finalTarget=$(echo "$image" | cut -f1 -d '#' -)
    time (DOCKER_TARGET="$finalTarget" docker-wrapper-run "$@")
  done
)

# Runs maven in a container as the user
# see https://github.com/ebpro/docker-maven
docker-mvn() (
  _docker_env
  docker run \
    --env IMAGE_NAME="$IMAGE_NAME" \
    --env GITHUB_LOGIN="$GITHUBLOGIN" \
    --env GITHUB_TOKEN="$GITHUBTOKEN" \
    --env SONAR_URL="$SONAR_URL" \
    --env SONAR_TOKEN="$SONAR_TOKEN" \
    --env SONAR_URL="$SONAR_URL" \
    --env SONAR_TOKEN="$SONAR_TOKEN" \
    --env S6_LOGGING=1 \
    --env S6_BEHAVIOUR_IF_STAGE2_FAILS \
    --volume "${HOME}/.m2":"/home/user/.m2" \
    --volume "${HOME}/.ssh":"/home/user/.ssh" \
    --volume "${HOME}/.gitconfig":"/home/user/.gitconfig" \
    --volume "$(pwd)":"/usr/src/mymaven" \
    --workdir /usr/src/mymaven \
    --rm \
    --env PUID="$(id -u)" -e PGID="$(id -g)" \
    --env MAVEN_CONFIG=/home/user/.m2 \
    "${MAVEN_IMAGE:-${CI_MAVEN_DEFAULT_IMAGE}}" \
    runuser --user user \
    --group user \
    -- mvn --errors --threads 1C --color always --strict-checksums \
    -Duser.home=/home/user \
    --settings /usr/src/mymaven/docker/ci-settings.xml "$@"
)

docker-sonar-analysis() (
  docker-mvn -P jacoco,sonar \
    -Dsonar.branch.name="$(git rev-parse --abbrev-ref HEAD | tr / _)" \
    verify sonar:sonar
)

new-java-project() (
  if [[ ! $# -eq 2 ]]; then
    echo "Usage: $0 <projectname> <groupid> [version]"
    exit 1
  fi

  _init

  PROJECT_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  GROUP_ID=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  VERSION="${3:-1.0-SNAPSHOT}"

  printf "${_B_TITLE}Creating Java project${_E_TITLE}\n"
  printf "\t Archetype : ${CI_JAVA_DEFAULT_ARCHETYPE_GROUPID}:${CI_JAVA_DEFAULT_ARCHETYPE_ARTIFACTID}:${CI_JAVA_DEFAULT_ARCHETYPE_VERSION}\n"
  printf "\t Artefact  : ${GROUP_ID}:${PROJECT_NAME}:${VERSION}\n"
  _check_variables GITHUBLOGIN GITHUBORG GITHUBTOKEN
  mvn --quiet --color=always --batch-mode archetype:generate \
    -DarchetypeGroupId="${CI_JAVA_DEFAULT_ARCHETYPE_GROUPID}" \
    -DarchetypeArtifactId="${CI_JAVA_DEFAULT_ARCHETYPE_ARTIFACTID}" \
    -DarchetypeVersion="${CI_JAVA_DEFAULT_ARCHETYPE_VERSION}" \
    -DgithubAccount="${GITHUBORG}" \
    -DgroupId="${GROUP_ID}" \
    -DartifactId="${PROJECT_NAME}" \
    -Dversion="${VERSION}" &&
    cd "${PROJECT_NAME}" &&
    printf "${_B_TITLE}  Gitflow init${_E_TITLE}\n" &&
    git flow init -d && git add . && git commit --quiet -m "sets initial release." &&
    printf "${_B_TITLE}  gh-pages branch creation${_E_TITLE}\n" &&
    git checkout --orphan gh-pages &&
    git rm -rf --quiet . && touch index.html &&
    git add . &&
    git commit --quiet -m "sets initial empty site." &&
    git checkout develop &&
    printf "${_B_TITLE}  GitHub reposirory creation${_E_TITLE}\n" &&
    gh repo create "${GITHUBORG}/${PWD##*/}" --disable-wiki --private --source=. &&
    printf "${_B_TITLE}  Generate a default deploy key${_E_TITLE}\n" &&
    _generate_and_install_new_deploy_key "${GITHUBORG}" "${PROJECT_NAME}" &&
    git push origin --mirror --quiet &&
    gh repo view --web
)

_generate_and_install_new_deploy_key() (
  tmpKeydir=$(mktemp --directory /tmp/ci-wrappers.XXXXXX)
  ssh-keygen -q -t ed25519 -C "git@github.com:${1}/${2}.git" -N "" -f "${tmpKeydir}/key"
  gh repo deploy-key add --allow-write "${tmpKeydir}/key.pub"
  gh secret set SSH_PRIVATE_KEY <"${tmpKeydir}/key"
  rm -rf tmpKeydir
)

# create a github hosted runner in a container for the current repo
github-runner-repo() (
  local workdir
  workdir=$(mktemp --directory "/tmp/ghrunner-${GITHUBORG}_${PWD##*/}_XXXXXX")
  docker run -d --restart always --name ghrunner_$(echo "$workdir" | cut -d '-' -f 2) \
    -e REPO_URL="https://github.com/${GITHUBORG}/${PWD##*/}" \
    -e RUNNER_NAME_PREFIX="${GITHUBORG}-${PWD##*/}-runner" \
    -e ACCESS_TOKEN="${GITHUBTOKEN}" \
    -e RUNNER_WORKDIR="${workdir}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${workdir}":"${workdir}" \
    myoung34/github-runner:latest
)

# create a github hosted runner in a container for the org in $GITHUBORG
github-runner-org() (
  local workdir
  workdir=$(mktemp --directory "/tmp/ghrunner-${GITHUBORG}_XXXXXX")
  docker run -d --restart always --name ghrunner_$(echo "$workdir" | cut -d '-' -f 2) \
    -e REPO_URL="https://github.com/${GITHUBORG}/${PWD##*/}" \
    -e RUNNER_NAME_PREFIX="${GITHUBORG}-${PWD##*/}-runner" \
    -e ACCESS_TOKEN="${GITHUBTOKEN}" \
    -e RUNNER_WORKDIR="${workdir}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${workdir}":"${workdir}" \
    -e RUNNER_SCOPE="org" \
    -e ORG_NAME="${GITHUBORG}" \
    myoung34/github-runner:latest
)