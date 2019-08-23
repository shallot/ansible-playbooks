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

# https://docs.ansible.com/ansible/latest/reference_appendices/config.html
ENV['ANSIBLE_CONFIG'] ||= File.join(__dir__, '.ansible.cfg')

# https://api.rubyonrails.org/classes/Hash.html#method-i-symbolize_keys
# https://docs.ruby-lang.org/en/trunk/Object.html#method-i-send
# https://docs.ruby-lang.org/en/trunk/Module.html#method-i-define_method
Hash.send(:define_method, :symbolize_keys!) do
  keys.each do |key|
    self[(key.to_sym rescue key) || key] = delete(key)
  end
end

# https://www.vagrantup.com/docs/vagrantfile/version.html
Vagrant.configure('2') do |vagrant|

  # https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html
  ansible_extra_vars = {
  }

  # https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html
  ansible_host_groups = {
  }

  # https://docs.ruby-lang.org/en/trunk/File.html#method-c-expand_path
  ansible_host_vars_directory = File.expand_path('host_vars', __dir__)

  # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
  vagrant.vm.box_check_update = false
  vagrant.vm.post_up_message = nil

  # https://docs.ruby-lang.org/en/trunk/Dir.html#method-c-glob
  Dir.glob("#{ansible_host_vars_directory}/*.test").sort.each do |file|

    # https://docs.ruby-lang.org/en/trunk/File.html#method-c-basename
    hostname = File.basename(file)

    # https://docs.ruby-lang.org/en/trunk/YAML.html
    hostvars = YAML.load_file(file)

    # https://docs.ruby-lang.org/en/trunk/Hash.html#method-i-fetch
    hostvars.fetch('vagrant_groups', []).each do |name|
      ansible_host_groups[name] ||= []
      ansible_host_groups[name] << hostname
    end

    # https://www.vagrantup.com/docs/multi-machine/
    vagrant.vm.define(hostname) do |config|

      # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
      config.vm.box = hostvars.fetch('vagrant_box', 'debian/contrib-stretch64')

      # https://www.vagrantup.com/docs/virtualbox/configuration.html
      config.vm.provider('virtualbox') do |virtualbox|
        virtualbox.cpus = hostvars.fetch('vagrant_cpus', 1)
        virtualbox.gui = hostvars.fetch('vagrant_gui', false)
        virtualbox.memory = hostvars.fetch('vagrant_memory', 256)
      end

      # https://www.vagrantup.com/intro/getting-started/networking.html
      networks_groups = hostvars.fetch('vagrant_networks', [])
      networks_groups.each do |networks|
        networks.each do |type, settings|
          settings.symbolize_keys!
          config.vm.network(type, **settings)
        end
      end

      # https://docs.ansible.com/ansible/latest/user_guide/playbooks.html
      playbooks = hostvars.fetch('vagrant_playbooks', [])
      playbooks.each do |playbook|

        # https://www.vagrantup.com/docs/provisioning/ansible.html
        config.vm.provision('ansible') do |ansible|
          ansible.compatibility_mode = '2.0'
          ansible.extra_vars = ansible_extra_vars
          ansible.groups = ansible_host_groups
          ansible.playbook = File.join(__dir__, playbook)
        end

      end

      # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
      settings = hostvars.fetch('vagrant_settings', {})
      settings['hostname'] = hostname
      settings.each { |key, value| config.vm.send("#{key}=", value) }

    end

  end

end
