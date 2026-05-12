import 'package:cloud_firestore/cloud_firestore.dart';

import 'task.dart';

// Classe responsavel por conversar com o Cloud Firestore.
// A tela chama estes metodos e nao precisa conhecer os detalhes do banco.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore, required this.userId})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String userId;

  // Cada usuario possui sua propria subcolecao de tarefas:
  // users/{uid}/tasks/{taskId}
  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // Stream cria uma leitura em tempo real. Sempre que o Firestore mudar,
  // a lista da tela sera atualizada automaticamente.
  Stream<List<Task>> watchTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Task.fromDocument).toList());
  }

  // CREATE: adiciona uma nova tarefa ao Firestore.
  Future<void> addTask({required String title, required String description}) {
    return _tasksCollection.add({
      'title': title,
      'description': description,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE: altera titulo e descricao de uma tarefa existente.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
  }) {
    return _tasksCollection.doc(taskId).update({
      'title': title,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE: muda apenas o campo booleano que indica se a tarefa foi concluida.
  Future<void> toggleTaskDone({required String taskId, required bool isDone}) {
    return _tasksCollection.doc(taskId).update({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE: remove o documento da tarefa no Firestore.
  Future<void> deleteTask(String taskId) {
    return _tasksCollection.doc(taskId).delete();
  }
}
