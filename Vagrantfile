# Copyright (c) 2018-present eyeo GmbH
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# https://ruby-doc.org/stdlib/libdoc/yaml/rdoc/YAML.html
require 'yaml'

# https://www.vagrantup.com/docs/vagrantfile/vagrant_version.html
Vagrant.require_version '>= 2.0.0'

# Attempt using Ansible and its dependencies from the virtual environment
# created when running playbook bootstrap-localhost.yml, unless Vagrant was
# invoked in an activated virtual environment in the first place. Refer to
# https://virtualenv.pypa.io/en/latest/userguide/#activate-script for details
unless ENV.key?('VIRTUAL_ENV')
  if File.file?(File.join(__dir__, 'builds/virtualenv/bin/ansible'))
    ENV['VIRTUAL_ENV'] = File.join(__dir__, 'builds/virtualenv')
    ENV['PATH'] = ENV['VIRTUAL_ENV'] + '/bin:' + ENV['PATH']
  end
end

# https://api.rubyonrails.org/classes/Hash.html#method-i-symbolize_keys
# https://docs.ruby-lang.org/en/trunk/Object.html#method-i-send
# https://docs.ruby-lang.org/en/trunk/Module.html#method-i-define_method
Hash.send(:define_method, :symbolize_keys!) do
  keys.each do |key|
    self[(key.to_sym rescue key) || key] = delete(key)
  end
end

# Poor man's detection of whether a Vagrant VM has already been provisioned
# https://stackoverflow.com/questions/24855635/check-if-vagrant-provisioning-has-been-done
def provisioned?(vm_name, provider = nil)
  provider ||= ENV['VAGRANT_DEFAULT_PROVIDER']
  provider ||= 'libvirt'
  File.exist?(".vagrant/machines/#{vm_name}/#{provider}/action_provision")
end

# This machine's existence is a prerequisite for successful Icinga SSH agent
# provisioning
ICINGA_SERVER_VM = 'icinga-0.test'.freeze

# https://www.vagrantup.com/docs/vagrantfile/version.html
Vagrant.configure('2') do |vagrant|

  # https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html
  ansible_host_groups = {}

  # https://docs.ruby-lang.org/en/trunk/File.html#method-c-expand_path
  ansible_host_vars_directory = File.expand_path('host_vars', __dir__)

  # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
  vagrant.vm.box_check_update = false
  vagrant.vm.post_up_message = nil

  # https://docs.ruby-lang.org/en/trunk/Dir.html#method-c-glob
  Dir.glob("#{ansible_host_vars_directory}/*.test").sort.each do |file|

    # https://docs.ruby-lang.org/en/trunk/File.html#method-c-basename
    hostname = File.basename(file)

    # host_vars/vagrant-runner-0.test
    next if hostname == 'vagrant-runner-0.test'

    # https://docs.ruby-lang.org/en/trunk/YAML.html
    hostvars = YAML.load_file(file)

    # https://docs.ruby-lang.org/en/trunk/Hash.html#method-i-fetch
    hostvars.fetch('vagrant_groups', []).each do |name|
      ansible_host_groups[name] ||= []
      ansible_host_groups[name] << hostname
    end

    # https://docs.ansible.com/ansible/latest/user_guide/playbooks_tags.html
    # https://www.vagrantup.com/docs/provisioning/ansible_common.html#tags
    ansible_tags = [
      'all'
    ]

    # https://docs.ruby-lang.org/en/trunk/Hash.html#method-i-fetch
    hostvars.fetch('vagrant_tags', []).each do |name|
      ansible_tags.push(name)
    end

    # https://www.vagrantup.com/docs/multi-machine/
    vagrant.vm.define(hostname) do |config|

      # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
      config.vm.box = hostvars.fetch('vagrant_box', 'debian/buster64')

      # https://www.vagrantup.com/docs/virtualbox/configuration.html
      config.vm.provider('virtualbox') do |virtualbox|
        virtualbox.cpus = hostvars.fetch('vagrant_cpus', 1)
        virtualbox.gui = hostvars.fetch('vagrant_gui', false)
        virtualbox.memory = hostvars.fetch('vagrant_memory', 256)
      end

      # https://github.com/vagrant-libvirt/vagrant-libvirt#domain-specific-options
      config.vm.provider('libvirt') do |libvirt|
        libvirt.cpus = hostvars.fetch('vagrant_cpus', 1)
        libvirt.memory = hostvars.fetch('vagrant_memory', 384)
      end

      # https://www.vagrantup.com/intro/getting-started/networking.html
      networks_groups = hostvars.fetch('vagrant_networks', [])
      networks_groups.each do |networks|
        networks.each do |type, settings|
          settings.symbolize_keys!
          config.vm.network(type, **settings)
        end
      end

      # provision-icinga-ssh-agents.yml
      if provisioned?(ICINGA_SERVER_VM) || hostname == ICINGA_SERVER_VM
        hostvars['vagrant_groups'] << 'icinga-ssh-agents'
        ansible_host_groups['icinga-ssh-agents'] << hostname
      end

      # https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html
      ansible_extra_vars = {}
      ansible_extra_vars = fill_extra_vars(hostvars, ansible_extra_vars)

      # https://docs.ansible.com/ansible/latest/user_guide/playbooks.html
      playbooks = hostvars.fetch('vagrant_playbooks', [])
      playbooks << 'provision-icinga-ssh-agents.yml' if
        provisioned?(ICINGA_SERVER_VM) || hostname == ICINGA_SERVER_VM
      playbooks.each do |playbook|

        # https://www.vagrantup.com/docs/provisioning/ansible.html
        config.vm.provision('ansible') do |ansible|
          ansible.compatibility_mode = '2.0'
          ansible.extra_vars = ansible_extra_vars
          ansible.tags = ansible_tags
          ansible.groups = ansible_host_groups
          ansible.playbook = File.join(__dir__, playbook)
        end

      end

      # https://www.vagrantup.com/docs/synced-folders/rsync.html
      if hostvars.fetch('vagrant_rsync', false)

        # https://www.vagrantup.com/docs/synced-folders/rsync.html#options
        rsync_options = {}
        rsync_options[:rsync__ownership] = true

        # Avoid --copy-links (which is included by default) because it would
        # cause the synchronization to fail due to infinite recursion when the
        # source directory contains links to paths within itself.
        # See https://github.com/hashicorp/vagrant/issues/5471 for details.
        rsync_args = ['--archive', '--compress', '--delete', '--verbose']
        rsync_options[:rsync__args] = rsync_args

        # Exclude transient data as well as the Git sub-modules because at this
        # point only the playbooks repository itself is required, and in one
        # single case only. Refer to the provision-ansible-masters.yml playbook
        # and the host_vars/admin-0.test file for details.
        rsync_exclude = ['.vagrant/', 'builds/', 'roles/']
        rsync_options[:rsync__exclude] = rsync_exclude

        # https://www.vagrantup.com/docs/synced-folders/rsync.html#example
        config.vm.synced_folder('.', '/vagrant', type: 'rsync', **rsync_options)

      else

        # https://www.vagrantup.com/docs/synced-folders/basic_usage.html#disabling
        config.vm.synced_folder('.', '/vagrant', disabled: true)

      end

      # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
      settings = hostvars.fetch('vagrant_settings', {})
      settings['hostname'] = hostname
      settings.each { |key, value| config.vm.send("#{key}=", value) }

    end

  end

end

def fill_extra_vars(hostvars, ansible_extra_vars)
  # Ansible extra vars per ansible group.
  # These are used for tests only and shouldn't go into group_vars.
  # Otherwise they would take precedence over values defined in production.
  extra_vars_map = {
    # roles/icinga/ssh-agent/tasks/main.yml
    'icinga-ssh-agents' => {
      'icinga_ssh_agent_server_associations' => [{
        'name' => 'icinga-0.test',
        'user' => 'nagios',
        'service' => 'icinga2'
      }],
      'icinga_ssh_agent_ipv4_address' =>
        hostvars['vagrant_networks'][0]['private_network'][:ip]
    },

    # tasks/backup.yml
    'backup-hosts' => {
      'automated_backup_server_key' => '/opt/backup/keys/id_ed25519',
      'automated_backup_server_directory' => '/var/backups'
    }
  }

  extra_vars_map.each do |key, value|
    ansible_extra_vars = ansible_extra_vars.merge(value) \
      if hostvars['vagrant_groups'].include?(key)
  end

  ansible_extra_vars
end
