#import sys
#from pprint import pformat

class FilterModule(object):
    def filters(self):
        return { 'ini_input_from_dict': self.ini_input_from_dict }

    def ini_input_from_dict(self, arg):
        ret = []
        for ini_file, configurations in arg.items():
            if type(configurations) is not dict:
#                sys.stderr.write("configurations: " + str(configurations) + "\n")
                continue
            config = {}
            for configuration, sections in configurations.items():
                if type(sections) is not dict:
                    config[configuration] = sections
                    continue
#                sys.stderr.write("found dict sections, will now use config: " + pformat(config) + "\n")
                for section, optionvaluepairs in sections.items():
                    for option, value in optionvaluepairs.items():
                        ret.append(dict(
                                    ini_file=ini_file,
                                    config=config,
                                    section=section,
                                    option=option,
                                    value=value
                                   )
                        )
        return ret
