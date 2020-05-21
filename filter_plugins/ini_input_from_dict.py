class FilterModule(object):
    def filters(self):
        return { 'ini_input_from_dict': self.ini_input_from_dict }

    def ini_input_from_dict(self, arg):
        ret = []
        for ini_file, subdict in arg.items():
            for configuration, subsubdict in subdict.items():
                for section, subsubsubdict in subdict.items():
                    for option, value in subsubsubdict.items():
                        ret.append(dict(
                                    ini_file=ini_file,
                                    configuration=configuration,
                                    section=section,
                                    option=option,
                                    value=value
                                   )
                        )
        return ret
