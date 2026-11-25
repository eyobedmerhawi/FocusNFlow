
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    return user;
  }

  // Create a profile if it does not already exist.
  Future<void> createUserProfile() async {
    final user = _currentUser;
    final userRef = _firestore.collection('users').doc(user.uid);

    final existingProfile = await userRef.get();

    if (existingProfile.exists) {
      return;
    }

    await userRef.set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Read the signed-in user's profile.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _currentUser;

    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();

    return snapshot.data();
  }

  // Create a task owned by the signed-in user.
  Future<String> createTask({
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    final user = _currentUser;

    final taskData = <String, dynamic>{
      'userId': user.uid,
      'title': title,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (description != null) {
      taskData['description'] = description;
    }

    if (dueAt != null) {
      taskData['dueAt'] = Timestamp.fromDate(dueAt);
    }

    final taskRef =
        await _firestore.collection('tasks').add(taskData);

    return taskRef.id;
  }

  // Read tasks belonging to the signed-in user.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyTasks() {
    final user = _currentUser;

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  // Update the completion status of a task.
  Future<void> setTaskCompleted({
    required String taskId,
    required bool completed,
  }) async {
    _currentUser;

    await _firestore.collection('tasks').doc(taskId).update({
      'completed': completed,
    });
  }

  // Delete a task.
  Future<void> deleteTask(String taskId) async {
    _currentUser;

    await _firestore.collection('tasks').doc(taskId).delete();
  }
}
