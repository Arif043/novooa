"""Kokoro-Token-IDs, gemeinsam genutzt von Tokens und Stil."""

from .phonemizer import phonemize


def kokoro_token_ids(text, parameters):
    language = required_language(parameters)
    token_map = required_token_map(parameters)
    return token_ids(phonemize(text, language, "Kokoro"), token_map)


def required_language(parameters):
    language = parameters.get("language")
    if not isinstance(language, str) or not language:
        raise ValueError("Die Kokoro-Transformation benötigt eine Sprache.")
    return language


def required_token_map(parameters):
    token_map = parameters.get("tokenIdMap")
    if not isinstance(token_map, dict) or not all(isinstance(value, int) for value in token_map.values()):
        raise ValueError("Die Kokoro-Transformation benötigt eine Tokenzuordnung.")
    return token_map


def token_ids(pronunciation, token_map):
    tokens = [token_map[phoneme] for phoneme in pronunciation if phoneme in token_map]
    if not tokens:
        raise ValueError("Der Text konnte nicht in Kokoro-Tokens umgewandelt werden.")
    return tokens
