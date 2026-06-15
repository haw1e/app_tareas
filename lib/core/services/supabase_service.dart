import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/models/user_profile.dart';
import '../../features/tasks/models/task_model.dart';
import '../../features/tasks/models/folder_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Ya no dependemos de un backend Node.js externo.
  // Mantenemos los parámetros opcionales en el constructor para no romper 
  // el código donde se instancia la clase en el resto de la app.
  SupabaseService({String? adminApiUrl, String? adminApiKey});

  // 1. LogIn
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Desconectar
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // 2. Obtener el perfil del usuario actual
  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  // 3. Crear trabajador puro usando API Admin (resuelve el error)
  Future<void> createWorkerAccount({
    required String email, 
    required String password, 
    required String fullName
  }) async {
    // Creamos al usuario en la base de datos de Auth nativa de Supabase
    final res = await _client.auth.signUp(
      email: email,
      password: password,
    );
    
    if (res.user != null) {
      await _client.from('profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'full_name': fullName,
        'role': 'worker',
      });
    }
  }

  // 4. Stream de tareas en Tiempo Real + Filtro de subcarpeta
  Stream<List<Task>> streamTasks({bool isWorker = false, String? folderId}) {
    return _client.from('tasks').stream(primaryKey: ['id']).asyncMap((maps) async {
      List<Task> tasks = maps.map((map) => Task.fromJson(map)).toList();

      // Cargar nombres de perfiles
      final profilesRes = await _client.from('profiles').select('id, full_name');
      final Map<String, String> profileNames = {
        for (var p in profilesRes) p['id'] as String: p['full_name'] as String
      };

      // Cargar nombres de carpetas y relaciones
      final taskFoldersRes = await _client.from('task_folders').select('task_id, folder_id, folders(name)');
      final Map<String, String> taskFolderNames = {};
      final Map<String, String> taskFolderIds = {};
      
      for (var tf in taskFoldersRes) {
        taskFolderIds[tf['task_id'] as String] = tf['folder_id'] as String;
        if (tf['folders'] != null && tf['folders'] is Map && tf['folders']['name'] != null) {
          taskFolderNames[tf['task_id'] as String] = tf['folders']['name'] as String;
        }
      }

      for (var task in tasks) {
        if (task.completedBy != null) {
          task.completedByName = profileNames[task.completedBy];
        }
        task.folderName = taskFolderNames[task.id];
      }

      // Si estamos dentro de una carpeta, podamos los que no pertenezcan
      if (folderId != null) {
        tasks = tasks.where((t) => taskFolderIds[t.id] == folderId).toList();
      }

      final now = DateTime.now();
      return tasks.where((task) {
        if (!isWorker) return true; // Admin ve todo
        if (task.scheduledFor == null) return true;
        return task.scheduledFor!.isBefore(now) || task.scheduledFor!.isAtSameMomentAs(now);
      }).toList();
    });
  }

  // 5. Marcar tarea como completada
  Future<void> completeTask(String taskId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('tasks').update({
      'status': 'completed',
      'completed_by': userId,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  // 6. Eliminar tareas
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> deleteAllTasks() async {
    // Supabase exige una condición para hacer deletes masivos por seguridad.
    // Usamos una condición que siempre se cumple para borrar todo.
    await _client.from('tasks').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }

  Future<void> deleteFolder(String folderId) async {
    await _client.from('folders').delete().eq('id', folderId);
  }

  Future<void> updateFolder(String folderId, String name) async {
    await _client.from('folders').update({'name': name}).eq('id', folderId);
  }

  Future<void> deleteUser(String userId) async {
    // Eliminamos solo el perfil del usuario de la tabla pública
    await _client.from('profiles').delete().eq('id', userId);
  }

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String role,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName,
      'role': role,
    }).eq('id', userId);
  }

  // 7. Crear Tarea
  Future<void> createTask({
    required String title,
    required String description,
    DateTime? scheduledFor,
    String? folderId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final taskData = await _client.from('tasks').insert({
      'title': title,
      'description': description,
      'status': 'pending',
      'created_by': userId,
      'scheduled_for': scheduledFor?.toIso8601String(),
    }).select().single();

    if (folderId != null) {
      await _client.from('task_folders').insert({
        'task_id': taskData['id'],
        'folder_id': folderId,
      });
    }
  }

  // 7.5 Actualizar Tarea
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
  }) async {
    await _client.from('tasks').update({
      'title': title,
      'description': description,
    }).eq('id', taskId);
  }

  // 8. Folders
  Stream<List<Folder>> streamFolders({String? parentId}) {
    return _client.from('folders').stream(primaryKey: ['id']).map((maps) {
      final folders = maps
          .map((map) => Folder.fromJson(map))
          .where((folder) => folder.parentId == parentId)
          .toList();
      folders.sort((a, b) => a.name.compareTo(b.name));
      return folders;
    });
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    await _client.from('folders').insert({
      'name': name,
      'parent_id': parentId,
    });
  }

  // 9. Profiles
  Stream<List<UserProfile>> streamProfiles() {
    return _client.from('profiles').stream(primaryKey: ['id']).map((maps) {
      return maps.map((map) => UserProfile.fromJson(map)).toList();
    });
  }
}