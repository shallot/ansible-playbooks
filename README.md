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

Next the [Ansible][ansible] software and some auxiliaries need to be
installed. On supported systems, the `provision-localhost.yml` playbook can
ensure the required dependencies are available:

    ansible-playbook --ask-become-pass provision-localhost.yml

By default, the tasks associated with the Vagrant providers of
virtual machines are not run, because there are multiple options,
typically [libvirt][libvirt] or [VirtualBox][virtualbox].

Some options come with eponymous example tags that invoke helper playbooks
which in turn set those up. One can either use the option `--tags
libvirt` to explicitly perform those, or run both the regular
(`untagged`) and `libvirt` tasks together:

    ansible-playbook -K --tags untagged,libvirt provision-localhost.yml

The analogous syntax should also work for `virtualbox`.

## If bootstrap doesn't work well

When the operating system is not supported, one needs to manually ensure the
dependencies being available before working with the repository.

If you can't run provision-localhost.yml on your system, you can manually
install the following list of dependencies required to run the *Ansible*
playbooks within this repository:

- The [Ansible][ansible] software, version 2.10
- The [Git][git] software, for fetching dependencies
- The [OpenSSH][openssh] client software
- The [Vagrant][vagrant] software, for virtual environments in development
  - Software that provides Vagrant with virtual machines, such as:
    - [libvirt][libvirt]
    - [VirtualBox][virtualbox]
- The [virtualenv][virtualenv] software, for isolating *Python* packages
  in development or in other specific use cases

The lists above do not include the dependencies of the listed items themselves.


[ansible]:    https://docs.ansible.com/ansible/latest/index.html
[clone]:      https://git-scm.com/docs/git-clone
[eyeo]:       https://eyeo.com/
[git]:        https://git-scm.com/
[libvirt]:    https://libvirt.org/
[openssh]:    https://www.openssh.com/
[playbook]:   https://docs.ansible.com/ansible/latest/user_guide/playbooks.html
[python]:     https://www.python.org/
[submodule]:  https://git-scm.com/docs/git-submodule
[vagrant]:    https://www.vagrantup.com/
[virtualbox]: https://www.virtualbox.org/
[virtualenv]: https://virtualenv.pypa.io/
