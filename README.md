# eyeo's Ansible Playbooks

This repository is a collection of [Ansible][ansible] [playbooks][playbook]
and associated resources used to operate the infrastructure at [eyeo][eyeo].

## Bootstrap

In order to prepare the local system for development or provisioning of any
environment, first [clone][clone] the [Git][git] repository:

    git clone https://gitlab.com/eyeo/devops/ansible-playbooks

Now `cd` to the local repository and then fetch the [submodules][submodule]
that populate the `roles/` directory therein:

    git submodule update --init

Next the [Ansible][ansible] software and some auxiliaries need to be installed,
a list of which can be found in the **Dependencies** section below.
On supported systems, the `provision-localhost.yml` playbook can ensure the
required dependencies to be available:

    ansible-playbook --ask-become-pass provision-localhost.yml

By default, the tasks associated with [VirtualBox][virtualbox] are not run.
One can either use the `--tags virtualbox` option to explicitly perform those,
or run both the regular (`untagged`) and `virtualbox` tasks together:

    ansible-playbook -K --tags untagged,virtualbox provision-localhost.yml

When the operating system is not supported, one needs to manually ensure the
dependencies being available before working with the repository.

## Dependencies

Below please find a list of dependencies required to run the *Ansible* playbooks
within this repository:

- The [Ansible][ansible] software, version 2.7
- The [Git][git] software, for fetching dependencies
- The [OpenSSH][openssh] client software

For development a few more tools are needed:

- The [Vagrant][vagrant] software, for operating virtual environments
- The [VirtualBox][virtualbox] software, a hypervisor for virtual machines
- The [virtualenv][virtualenv] software, for isolating *Python* packages

The lists above do not include the dependencies of the listed items themselves.


[ansible]:    https://docs.ansible.com/ansible/latest/index.html
[clone]:      https://git-scm.com/docs/git-clone
[eyeo]:       https://eyeo.com/
[git]:        https://git-scm.com/
[openssh]:    https://www.openssh.com/
[playbook]:   https://docs.ansible.com/ansible/latest/user_guide/playbooks.html
[python]:     https://www.python.org/
[submodule]:  https://git-scm.com/docs/git-submodule
[vagrant]:    https://www.vagrantup.com/
[virtualbox]: https://www.virtualbox.org/
[virtualenv]: https://virtualenv.pypa.io/
