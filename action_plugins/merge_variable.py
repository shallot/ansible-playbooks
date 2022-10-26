# Copyright (c) 2019-present eyeo GmbH
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

"""An Ansible action plugin for explicit merging of dict and list facts.

This software is inspired by the `ansible_merge_vars` plugin published
at https://github.com/leapfrogonline/ansible-merge-vars and distributed
at https://pypi.org/project/ansible-merge-vars/
"""

import ansible.errors
import ansible.plugins.action
import ansible.utils.vars


# https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#action-plugins
class ActionModule(ansible.plugins.action.ActionBase):
    """An Ansible action plugin for merging variables.

    The plugin is able to merge all variables with a given `suffix`
    into an Ansible fact variable with the given `name`.
    It requires either a `default` to be provided or the variable with
    the given `name` to be defined beforehand, in which case that
    pre-defined variable value will override anything else to be merged.
    Note that any variables to merge must be of the same type as the
    default, either `list` or `dict`.
    """

    def run(self, task_vars=None, **kwargs):
        """Invoked by Ansible when the action module is triggered."""
        name = self.__get_identifier('name')
        suffix = self.__get_identifier('suffix')

        recursive = self.__get_option('recursive')

        default = self.__get_default(name, task_vars)
        expected_type = type(default)
        values = self.__get_values(suffix, task_vars, expected_type)

        if values == []:
            merged = default
        elif issubclass(expected_type, list):
            merged = merge_lists(values)
        elif issubclass(expected_type, dict):
            merged = merge_dicts(values, recursive)
        else:
            message = 'Cannot merge variables of type {}'.format(expected_type)
            raise ansible.errors.AnsibleError(message)

        result = {
            'ansible_facts': {name: merged},
            'changed': False,
        }

        return result

    def __get_default(self, name, task_vars):
        """Fetch the default for the variable with the given name."""
        current = task_vars.get(name)
        default = self._task.args.get('default', current)

        if default is None:
            message = 'No explicit default and {} is undefined'.format(name)
            raise ansible.errors.AnsibleError(message)

        default = self._templar.template(default)
        return default

    def __get_identifier(self, key):
        """Fetch a mandatory task parameter that must be an identifier."""
        identifier = self._task.args.get(key, '')

        if not ansible.utils.vars.isidentifier(identifier):
            pattern = '{} "{}" is not a valid identifier'
            message = pattern.format(key, identifier)
            raise ansible.errors.AnsibleError(message)

        return identifier

    def __get_values(self, suffix, task_vars, expected_type):
        """Fetch the list of values to merge based on the given suffix."""
        keys = sorted(key for key in task_vars.keys() if key.endswith(suffix))
        values = [self._templar.template(task_vars[key]) for key in keys]

        if any(not isinstance(value, expected_type) for value in values):
            message = 'All values to merge must be {}'.format(expected_type)
            raise ansible.errors.AnsibleError(message)

        return values

    def __get_option(self, option):
        """Fetch a optional task parameter. defaults to 'None'."""
        option = self._task.args.get(option)

        return option


def merge_dicts(dictionaries, recursive):
    """Merge the given dictionaries into a single one."""
    result = {}

    if recursive is True:
      for to_merge in dictionaries:
        for key, value in to_merge.items():
          if (key in result and isinstance(result[key], dict)
            and isinstance(to_merge[key], dict)):

            to_merge[key] = merge_dicts([result[key], to_merge[key]], recursive)

          result[key] = to_merge[key]

    else:
      for item in dictionaries:
          result.update(item)

    return result


def merge_lists(lists):
    """Merge the given lists into a single one without duplicate items."""
    result = []

    for item in lists:
        result.extend(value for value in item if value not in result)

    return result
