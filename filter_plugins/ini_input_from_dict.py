class FilterModule(object):
    def filters(self):
        return { 'ini_input_from_dict': self.ini_input_from_dict }

    def ini_input_from_dict(self, arg):
        ret = []
        for ini_file, configurations in arg.items():
            if type(configurations) is not dict:
                continue
            for configuration, sections in configurations.items():
                if type(sections) is not dict:
                    continue
                for section, optionvaluepairs in sections.items():
                    for option, value in optionvaluepairs.items():
                        ret.append(dict(
                                    ini_file=ini_file,
                                    configuration=configuration,
                                    section=section,
                                    option=option,
                                    value=value
                                   )
                        )
        return ret
