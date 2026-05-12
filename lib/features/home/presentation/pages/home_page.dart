import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../tasks/data/task.dart';
import '../../../tasks/data/task_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.email});

  final String email;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TaskRepository _taskRepository;

  @override
  void initState() {
    super.initState();

    // Pegamos o uid do Firebase Auth para salvar tarefas separadas por usuario.
    // Como a Home so abre depois do login, currentUser deve existir aqui.
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw StateError('Nao existe usuario logado para carregar tarefas.');
    }

    _taskRepository = TaskRepository(userId: userId);
  }

  Future<void> _logout() async {
    // signOut remove a sessao local do Firebase Auth.
    // Depois disso, currentUser volta a ser null.
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _openTaskForm({Task? task}) async {
    final isEditing = task != null;

    // O dialog devolve os textos prontos. Os controllers ficam dentro do
    // _TaskFormDialog, que sabe o momento correto de liberar esses objetos.
    final result = await showDialog<_TaskFormResult>(
      context: context,
      builder: (_) => _TaskFormDialog(task: task),
    );

    if (result == null) {
      return;
    }

    try {
      if (isEditing) {
        // UPDATE: quando existe uma tarefa, atualizamos o documento dela.
        await _taskRepository.updateTask(
          taskId: task.id,
          title: result.title,
          description: result.description,
        );
      } else {
        // CREATE: quando nao existe tarefa, criamos um novo documento.
        await _taskRepository.addTask(
          title: result.title,
          description: result.description,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel salvar a tarefa.')),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    // Confirmacao simples para evitar apagar uma tarefa por engano.
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir tarefa'),
          content: Text('Deseja excluir "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      // DELETE: apagamos o documento usando o id da tarefa.
      await _taskRepository.deleteTask(task.id);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel excluir a tarefa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTaskForm,
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: StreamBuilder<List<Task>>(
        // READ: o StreamBuilder escuta o Firestore em tempo real.
        stream: _taskRepository.watchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nao foi possivel carregar as tarefas.'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? const <Task>[];

          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.checklist, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma tarefa cadastrada',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usuario logado: ${widget.email}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    // UPDATE: ao marcar o checkbox, atualizamos apenas isDone.
                    onChanged: (value) {
                      _taskRepository.toggleTaskDone(
                        taskId: task.id,
                        isDone: value ?? false,
                      );
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: task.description.isEmpty
                      ? Text('Usuario: ${widget.email}')
                      : Text(task.description),
                  onTap: () => _openTaskForm(task: task),
                  trailing: IconButton(
                    onPressed: () => _deleteTask(task),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Objeto simples usado para devolver os dados digitados no dialog.
// Assim a tela principal recebe valores prontos, e nao controllers.
class _TaskFormResult {
  const _TaskFormResult({required this.title, required this.description});

  final String title;
  final String description;
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({this.task});

  final Task? task;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    // Os campos comecam vazios ao criar, ou preenchidos ao editar.
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
  }

  @override
  void dispose() {
    // Como os controllers pertencem ao dialog, eles sao liberados quando o
    // proprio dialog sai da tela. Isso evita erro ao clicar em Salvar.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      _TaskFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O mesmo dialog serve para CREATE e UPDATE.
    return AlertDialog(
      title: Text(_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ex.: Estudar Firebase',
              ),
              validator: (value) {
                final title = value?.trim() ?? '';

                if (title.isEmpty) {
                  return 'Informe o titulo da tarefa.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descricao',
                hintText: 'Ex.: Fazer o CRUD da aula',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
