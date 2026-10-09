from importlib import import_module
from inspect import isabstract, isclass
from pkgutil import walk_packages

from .strategy import TransformationStrategy


def strategy_instances(*package_names):
    """Instanziiert alle konkreten Strategien in den Paketen samt Unterpaketen."""
    return [
        strategy()
        for package_name in package_names
        for module in package_modules(package_name)
        for strategy in module_strategies(module)
    ]


def package_modules(package_name):
    package = import_module(package_name)
    return [
        import_module(module.name)
        for module in walk_packages(package.__path__, f"{package_name}.")
        if not module.ispkg
    ]


def module_strategies(module):
    return [
        candidate
        for candidate in vars(module).values()
        if isclass(candidate)
        and issubclass(candidate, TransformationStrategy)
        and not isabstract(candidate)
        and candidate.__module__ == module.__name__
    ]
