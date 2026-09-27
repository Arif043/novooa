from importlib import import_module
from inspect import isclass
from pkgutil import iter_modules


def strategy_instances(package_name, strategy_type):
    return [
        strategy()
        for module in import_package_modules(package_name)
        for strategy in module_strategies(module, strategy_type)
    ]


def import_package_modules(package_name):
    package = import_module(package_name)
    return [
        import_module(module.name)
        for module in iter_modules(package.__path__, f"{package_name}.")
    ]


def module_strategies(module, strategy_type):
    return [
        candidate
        for candidate in vars(module).values()
        if isclass(candidate)
        and candidate is not strategy_type
        and issubclass(candidate, strategy_type)
        and candidate.__module__ == module.__name__
    ]
