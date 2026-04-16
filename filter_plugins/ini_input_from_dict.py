from pprint import pformat
from ansible.utils.display import Display

display = Display()

class FilterModule(object):
    def filters(self):
        return { 'ini_input_from_dict': self.ini_input_from_dict }

    def ini_input_from_dict(self, arg):
        display.v(f"Processing input for INI conversion: {list(arg)}")
        ret = []
        for ini_file, configurations in arg.items():
            if not isinstance(configurations, dict):
                display.v(f"For {ini_file}, parsed non-dict configurations: {str(configurations)}")
                continue
            config = {}
            for configuration, sections in configurations.items():
                if not isinstance(sections, dict):
                    config[configuration] = sections
                    display.v(f"For {ini_file}, parsed non-dict sections, passing it on as {configuration} config")
                    continue
                display.v(f"For {ini_file}, parsed dict sections, generating {configuration} with config: {pformat(config)}")
                for section, optionvaluepairs in sections.items():
                    display.v(f"For {ini_file}, adding INI entries in [{section}]...")
                    for option, value in optionvaluepairs.items():
                        display.vv(f"For {ini_file}, adding to [{section}]: {option}={value}")
                        ret.append(dict(
                                    ini_file=ini_file,
                                    config=config,
                                    section=section,
                                    option=option,
                                    value=value
                                   )
                        )
        return ret
