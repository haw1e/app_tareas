import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../core/services/supabase_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/models/folder_model.dart';
import '../../auth/models/user_profile.dart';

class AdminDashboard extends StatefulWidget {
  final UserProfile userProfile;
  final String? currentFolderId;
  final String? currentFolderName;

  const AdminDashboard({
    super.key, 
    required this.userProfile,
    this.currentFolderId,
    this.currentFolderName,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SupabaseService _supabaseService = SupabaseService(
    adminApiKey: Config.adminApiKey.isEmpty ? null : Config.adminApiKey,
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.currentFolderName ?? 'Admin Dashboard';
    final isRoot = widget.currentFolderId == null;

    return DefaultTabController(
      length: isRoot ? 3 : 2, // Si no es root, no mostramos usuarios
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: !isRoot 
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
              : null,
          actions: [
            if (isRoot)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                tooltip: 'Borrar todas las tareas',
                onPressed: () => _confirmDeleteAll(context),
              ),
            if (isRoot)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () => _confirmSignOut(context),
              )
          ],
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(text: 'Tareas', icon: Icon(Icons.task)),
              const Tab(text: 'Carpetas', icon: Icon(Icons.folder)),
              if (isRoot) const Tab(text: 'Usuarios', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTasksTab(),
            _buildFoldersTab(),
            if (isRoot) _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Scaffold(
      body: StreamBuilder<List<Task>>(
        stream: _supabaseService.streamTasks(isWorker: false, folderId: widget.currentFolderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: tasks.isEmpty
              ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No hay tareas aquí.', style: TextStyle(fontSize: 18))))])
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  key: ValueKey(task.id),
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.description),
                        const SizedBox(height: 4),
                        if (task.folderName != null)
                          Row(
                            children: [
                              const Icon(Icons.folder, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(task.folderName!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (task.status == 'completed')
                          Text(
                            'Completada por: ${task.completedByName ?? 'Desconocido'} el ${task.completedAt?.toLocal().toString().split('.')[0] ?? ''}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                          )
                        else
                          const Text('Estado: PENDIENTE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar tarea',
                          onPressed: () => _showEditTaskDialog(context, task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar tarea',
                          onPressed: () => _confirmDeleteTask(context, task.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_task',
        onPressed: () => _showCreateTaskDialog(context),
        backgroundColor: Colors.blueGrey[900],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Tarea'),
      ),
    );
  }

  Widget _buildFoldersTab() {
    return Scaffold(
      body: StreamBuilder<List<Folder>>(
        stream: _supabaseService.streamFolders(parentId: widget.currentFolderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final folders = snapshot.data ?? [];
          
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: folders.isEmpty 
              ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No hay carpetas.')))])
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return Card(
                  key: ValueKey(folder.id),
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.grey),
                    title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDashboard(
                            userProfile: widget.userProfile,
                            currentFolderId: folder.id,
                            currentFolderName: folder.name,
                          ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar carpeta',
                          onPressed: () => _showEditFolderDialog(context, folder),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar carpeta',
                          onPressed: () => _confirmDeleteFolder(context, folder.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_folder',
        onPressed: () => _showCreateFolderDialog(context),
        backgroundColor: Colors.grey[800],
        icon: const Icon(Icons.create_new_folder, color: Colors.white),
        label: const Text('Carpeta'),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Scaffold(
      body: StreamBuilder<List<UserProfile>>(
        stream: _supabaseService.streamProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final users = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                key: ValueKey(user.id),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rol: ${user.role.toUpperCase()} | ${user.email}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar usuario',
                        onPressed: () => _showEditUserDialog(context, user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar usuario',
                        onPressed: () => _confirmDeleteUser(context, user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_user',
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Trabajador', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar TODAS las tareas'),
        content: const Text('¿Estás seguro de que quieres eliminar todas las tareas de forma global?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabaseService.deleteAllTasks();
              if (!mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Todas las tareas han sido eliminadas.')),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabaseService.signOut();
              if (!mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabaseService.deleteTask(taskId);
              if (!mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Tarea eliminada')),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Tarea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              try {
                await _supabaseService.updateTask(
                  taskId: task.id,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Tarea actualizada')),
                );
                Navigator.pop(dialogContext);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error al actualizar tarea: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, String folderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar carpeta'),
        content: const Text('¿Deseas eliminar esta carpeta y sus relaciones?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabaseService.deleteFolder(folderId);
              if (!mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Carpeta eliminada')),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(BuildContext context, Folder folder) {
    final nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Carpeta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre de la carpeta'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _supabaseService.updateFolder(folder.id, nameController.text.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Carpeta actualizada')),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('¿Deseas eliminar este usuario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabaseService.deleteUser(userId);
              if (!mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado')),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserProfile user) {
    final nameController = TextEditingController(text: user.fullName);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre completo')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'worker', child: Text('Worker')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedRole = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _supabaseService.updateUserProfile(
                    userId: user.id,
                    fullName: nameController.text.trim(),
                    role: selectedRole,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Usuario actualizado')),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Crear Tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
                if (isLoading) const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          await _supabaseService.createTask(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            folderId: widget.currentFolderId,
                          );
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al crear tarea: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Nueva Carpeta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la carpeta'),
              ),
              if (isLoading) const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          await _supabaseService.createFolder(
                            nameController.text.trim(),
                            parentId: widget.currentFolderId,
                          );
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al crear carpeta: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Crear Trabajador'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre completo')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
                  if (isLoading) const Padding(padding: EdgeInsets.only(top: 16.0), child: CircularProgressIndicator())
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                    setState(() => isLoading = true);
                    try {
                      await _supabaseService.createWorkerAccount(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        fullName: nameController.text.trim(),
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  }
                },
                child: const Text('Registrar'),
              ),
            ],
          );
        }
      ),
    );
  }
}
