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
  export PATH="${CI_WRAPPER_HOME}/bin:$PATH"
```

## Usage

  - `ci-install-software` <br/>
    Installs GitHub CLI, Docker client, docker compose plugin, vagrant and terraform in `$CI_WRAPPERS_HOME`
  - `provision-docker-engine` <br/> 
    Installs docker in a vagrant VM.
  - `use-vagrant-docker` <br/>
    Set environment variables for Docker Client to use Docker Engine in the VM.
 
### Java+Maven with Docker
  
  A sample docker command to generate a maven from a archetype in the current directory. Remember that the host home directory is mounted
 /vagrant_data inthe VM and that bind mounts are done from the VM. 

  ```bash
  docker run --rm -it \
        --volume "/vagrant_data/.m2":/root/.m2 \
        --volume /vagrant_data$(echo $PWD|sed "s/$(echo $HOME|echo $HOME|sed 's/\//\\\//g')//"):/usr/src/mymaven \
        --workdir /usr/src/mymaven maven \
		mvn archetype:generate \
   			-DarchetypeGroupId=fr.ebruno.maven.archetypes \
			-DarchetypeArtifactId=maven-archetype-simple \
   			-DarchetypeVersion=0.1.3 \
   			-DgroupId=fr.univtln.bruno.samples \
   			-DartifactId=MyAppHelloWorld \
   			-Dversion=0.1.0-SNAPSHOT
  ```

### HTTP Proxy and wrappers

  - if you have an http proxy :
    - YOUR PASSWORD CAN'T CONTAINS CARACTERS FORBIDDEN IN URL
    - sets the needed variables `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY`
    - and adds the variables `VAGRANT_HTTP_PROXY`, `VAGRANT_HTTPS_PROXY` and `VAGRANT_NO_PROXY`
  - To install a docker engine with http proxy support in a Virtualbox VM with vagrant :
    - run `provision-docker-engine` once to create the VM
        - `docker-vagrant` is a wrapper for this specific Docker vagrant Box.
        - `docker-vagrant up` and `docker-vagrant halt` to create/start and stop the vm.
        - `docker-vagrant ssh` to log in the VM.
        - `docker-vagrant suspend`, `docker-vagrant resume` and `docker-vagrant status` to suspend, resume and get VM
          status.
        - `docker-vagrant destroy` to destroy it (**docker named volumes will be lost**).
    - `use-vagrant-docker` sets $DOCKER_HOST for the docker client in the current shell.
    - to test `docker run --rm hello-world`
    - `vagrant destroy` to destroy the VM AND THE DATA.


### Continuous Integration (C.I.)

  - `new-java-project testci fr.univtln.bruno.tests` <br/>
    Creates a new maven projects ready for C.I.
  - `docker-mvn` <br/>
    Wraps maven in a container (docker needed see beelow).<br/>
    For example to build a C.I. project: `docker-mvn clean verify`
  - `ci-github-runner-repo` or `ci-github-runner-org` <br/>
    Creates and register a new GitHub runner in a docker container for the current repository
    or the organisation (account).
  
