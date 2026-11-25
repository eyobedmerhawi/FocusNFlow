
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _tasksStream;

  bool _isTesting = false;
  String? _testResult;
  final Set<String> _busyTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tasksStream = _firestoreService.watchMyTasks();
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }
  }

  Future<void> _testFirestore() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      await _firestoreService.createUserProfile();

      final profile = await _firestoreService.getUserProfile();

      if (profile == null) {
        throw StateError('User profile was not found.');
      }

      final taskId = await _firestoreService.createTask(
        title: 'FocusNFlow Firestore Test',
        description: 'Testing Firestore integration',
      );

      if (!mounted) return;

      setState(() {
        _testResult =
            'SUCCESS!\n\n'
            'User profile created or found.\n'
            'Profile read successfully.\n'
            'Test task created.\n\n'
            'Task ID: $taskId';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore test completed successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _testResult = 'FIRESTORE TEST FAILED:\n\n$error';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore test failed. See details below.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _updateTask({
    required String taskId,
    required bool completed,
  }) async {
    if (_busyTaskIds.contains(taskId)) return;

    setState(() {
      _busyTaskIds.add(taskId);
    });

    try {
      await _firestoreService.setTaskCompleted(
        taskId: taskId,
        completed: completed,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed
                ? 'Task marked as completed!'
                : 'Task marked as incomplete!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update task: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyTaskIds.remove(taskId);
        });
      }
    }
  }

  Future<void> _confirmDeleteTask({
    required String taskId,
    required String title,
  }) async {
    if (_busyTaskIds.contains(taskId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text(
            'Are you sure you want to delete "$title"? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busyTaskIds.add(taskId);
    });

    try {
      await _firestoreService.deleteTask(taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete task: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyTaskIds.remove(taskId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusNFlow'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'You are logged in!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ??
                    user?.email ??
                    'Authenticated user',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isTesting ? null : _testFirestore,
                icon: const Icon(Icons.cloud_done),
                label: Text(
                  _isTesting
                      ? 'Testing Firestore...'
                      : 'Test Firestore Connection',
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 20),
                SelectableText(
                  _testResult!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _testResult!.startsWith('SUCCESS')
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'My Firestore Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tasksStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load tasks:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Loading tasks...'),
                    );
                  }

                  final tasks = snapshot.data!.docs;

                  if (tasks.isEmpty) {
                    return const Text('No tasks found.');
                  }

                  return Column(
                    children: tasks.map((task) {
                      final data = task.data();
                      final title =
                          data['title'] as String? ?? 'Untitled task';
                      final completed =
                          data['completed'] as bool? ?? false;
                      final isBusy = _busyTaskIds.contains(task.id);

                      return Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                value: completed,
                                onChanged: isBusy
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        _updateTask(
                                          taskId: task.id,
                                          completed: value,
                                        );
                                      },
                                title: Text(title),
                                subtitle: Text(
                                  'Completed: $completed\n'
                                  'Task ID: ${task.id}',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete task',
                              icon: const Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: isBusy
                                  ? null
                                  : () => _confirmDeleteTask(
                                        taskId: task.id,
                                        title: title,
                                      ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
