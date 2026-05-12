import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa uma tarefa dentro do aplicativo.
// Ele ajuda a transformar os documentos do Firestore em objetos Dart.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? createdAt;

  // Converte um documento vindo do Firestore para o nosso modelo Task.
  factory Task.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};

    return Task(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isDone: data['isDone'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
