const assistantResponseSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['answer', 'commands', 'knowledgeCommands'],
  'properties': {
    'answer': {'type': 'string'},
    'commands': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['type', 'label'],
        'properties': {
          'type': {
            'type': 'string',
            'enum': ['renameTask', 'addNode'],
          },
          'label': {'type': 'string'},
          'primitive': {
            'type': 'string',
            'enum': [
              'stringInput',
              'prompt',
              'readChannelEvent',
              'sendChannelMessage',
              'humanApproval',
              'script',
            ],
          },
          'kind': {
            'type': 'string',
            'enum': ['email', 'whatsapp', 'sms'],
          },
          'title': {'type': 'string'},
          'referenceName': {'type': 'string'},
          'description': {'type': 'string'},
          'value': {'type': 'string'},
          'instruction': {'type': 'string'},
          'recipient': {'type': 'string'},
          'message': {'type': 'string'},
        },
      },
    },
    'knowledgeCommands': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['type', 'label'],
        'properties': {
          'type': {
            'type': 'string',
            'enum': [
              'createKnowledgeNote',
              'updateKnowledgeNote',
              'deleteKnowledgeNote',
            ],
          },
          'label': {'type': 'string'},
          'noteId': {'type': 'string'},
          'title': {'type': 'string'},
          'content': {'type': 'string'},
        },
      },
    },
  },
};
