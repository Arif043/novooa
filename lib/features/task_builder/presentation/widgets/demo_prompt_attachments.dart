import '../../domain/entities/prompt_attachment.dart';

const demoPromptAttachments = [
  PromptAttachment(
    id: 'file.requirements.v1',
    storagePath: 'users/current/uploads/requirements.md',
    generation: '1',
    displayName: 'requirements.md',
    contentType: 'text/markdown',
    sizeBytes: 18420,
  ),
  PromptAttachment(
    id: 'file.contract.v3',
    storagePath: 'users/current/uploads/vertrag.pdf',
    generation: '3',
    displayName: 'vertrag.pdf',
    contentType: 'application/pdf',
    sizeBytes: 1240000,
  ),
  PromptAttachment(
    id: 'file.notes.v2',
    storagePath: 'users/current/uploads/notizen.txt',
    generation: '2',
    displayName: 'notizen.txt',
    contentType: 'text/plain',
    sizeBytes: 6200,
  ),
];
