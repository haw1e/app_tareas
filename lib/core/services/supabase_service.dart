import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/models/user_profile.dart';
import '../api_config.dart';
import '../../features/tasks/models/task_model.dart';
import '../../features/tasks/models/folder_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Admin API endpoint (self-hosted/service) to perform privileged operations.
  // Usa ApiConfig.baseUrl para seleccionar local/prod automáticamente.
  final String adminApiUrl;
  final String? adminApiKey;

  SupabaseService({String? adminApiUrl, this.adminApiKey})
      : adminApiUrl = adminApiUrl ?? ApiConfig.baseUrl;

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
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    final res = await _postJson('/create-worker', {
      'email': email,
      'password': password,
      'full_name': fullName,
    });

    if (res == null || res['user'] == null) {
      throw Exception('Failed to create worker account');
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
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/delete-task', {'id': taskId});
  }

  Future<void> deleteAllTasks() async {
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/delete-all-tasks', {});
  }

  Future<void> deleteFolder(String folderId) async {
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/delete-folder', {'id': folderId});
  }

  Future<void> updateFolder(String folderId, String name) async {
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/update-folder', {'id': folderId, 'name': name});
  }

  Future<void> deleteUser(String userId) async {
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/delete-user', {'id': userId});
  }

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String role,
  }) async {
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/update-user-profile', {
      'id': userId,
      'full_name': fullName,
      'role': role,
    });
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
    if (adminApiUrl.isEmpty) throw Exception('Admin API not configured');
    await _postJson('/update-task', {
      'id': taskId,
      'title': title,
      'description': description,
    });
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

  Uri _adminUri(String path) {
    final base = adminApiUrl.trim();
    if (base.isEmpty) {
      throw Exception('Admin API URL is not configured');
    }
    if (!base.toLowerCase().startsWith('http://') && !base.toLowerCase().startsWith('https://')) {
      throw Exception('Admin API URL must include http:// or https://: $base');
    }
    if (base.toLowerCase().startsWith('http://') && kReleaseMode) {
      throw Exception('Release admin API URL must use HTTPS: $base');
    }

    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  // --- Helper for admin API calls ---
  Future<Map<String, dynamic>?> _postJson(String path, Map body) async {
    final url = _adminUri(path);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (adminApiKey != null && adminApiKey!.isNotEmpty) {
      headers['x-admin-key'] = adminApiKey!;
    }

    final resp = await http
        .post(url, headers: headers, body: jsonEncode(body)) // Increased timeout to 30 seconds
        .timeout(const Duration(seconds: 30)); // If backend operations are slow, consider optimizing them instead of just increasing this.
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Admin API request failed (${resp.statusCode}): ${resp.body}');
    }
    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}