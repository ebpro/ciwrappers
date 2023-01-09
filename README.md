# C.I. Wrappers

A sets a utility bash functions for Continuous Integration C.I.

## Installation

Install with :

```bash
curl -s https://raw.githubusercontent.com/ebpro/ciwrappers/develop/get-ci-wrapper.sh | bash
```

To use it in the current shell :

```bash
source ~/.ci-wrappers/ci-wrappers.sh
```

You can add it to .bashrc or .zshrc :

```bash
export CI_WRAPPER_HOME=${HOME}/.ci-wrappers
[[ -f "${CI_WRAPPER_HOME}/ci-wrappers.sh" ]] && \
  source "${CI_WRAPPER_HOME}/ci-wrappers.sh" && \
  export PATH="${CI_WRAPPER_HOME}/PATH:$PATH"
```

## Usage

- `ci-install-software` <br/>
  Installs GitHub CLI, Docker client, docker compose plugin, vagrant and terraform in $CI_WRAPPERS_HOME
- `new-java-project testci fr.univtln.bruno.tests` <br/>
  Creates a new maven projects ready for C.I.
- `docker-mvn` <br/>
  Wraps maven in a container (docker needed see beelow).<br/>
  For example to build a C.I. project: `docker-mvn clean verify`
- `ci-github-runner-repo` or `ci-github-runner-org` <br/>
  Creates and register a new GitHub runner in a docker container for the current repository
  or the organisation (account).
- A docker engine with http proxy support in VM :
    - `docker-vagrant` is a wrapper for a specific Docker vagrant Box (Docker in a VBox VM).
        - `docker-vagrant up` and `docker-vagrant halt` to create/start and stop the vm.
        - `docker-vagrant ssh` to log in the VM.
        - `docker-vagrant suspend`, `docker-vagrant resume` and `docker-vagrant status` to suspend, resume and get VM
          status.
        - `docker-vagrant destroy` to destroy it (**docker named volumes will be lost**).
    - `use-vagrant-docker` to sets docker client to used in the current shell (sets $DOCKER_HOST).
    - `vagrant destroy` to destroy it.
