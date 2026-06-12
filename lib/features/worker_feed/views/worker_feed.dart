import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/config.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/models/folder_model.dart';
import '../../auth/models/user_profile.dart';

class WorkerFeed extends StatelessWidget {
  final UserProfile userProfile;
  final String? currentFolderId;
  final String? currentFolderName;
  
  const WorkerFeed({
    super.key, 
    required this.userProfile,
    this.currentFolderId,
    this.currentFolderName,
  });

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService(
      adminApiKey: Config.adminApiKey.isEmpty ? null : Config.adminApiKey,
    );
    final isRoot = currentFolderId == null;
    final title = currentFolderName ?? 'Mis Tareas';

    return DefaultTabController(
      length: 2,
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
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () => _confirmSignOut(context),
              )
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Tareas', icon: Icon(Icons.task)),
              Tab(text: 'Carpetas', icon: Icon(Icons.folder)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Vista de Tareas
            StreamBuilder<List<Task>>(
              stream: supabaseService.streamTasks(isWorker: true, folderId: currentFolderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) return const Center(child: Text('No hay tareas aquí.', style: TextStyle(fontSize: 18)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isCompleted = task.status == 'completed';

                    return Card(
                      key: ValueKey(task.id),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(task.description, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            if (task.folderName != null)
                              Row(
                                children: [
                                  const Icon(Icons.folder, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(task.folderName!, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            const SizedBox(height: 4),
                            if (isCompleted)
                              Text(
                                'Completada por: ${task.completedByName ?? 'Desconocido'}\nFecha: ${task.completedAt?.toLocal().toString().split('.')[0] ?? ''}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                              )
                            else
                              const Text('Pendiente', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        trailing: isCompleted 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800], 
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => supabaseService.completeTask(task.id),
                              child: const Text('TERMINAR'),
                            ),
                      ),
                    );
                  },
                );
              },
            ),

            // Vista de Carpetas
            StreamBuilder<List<Folder>>(
              stream: supabaseService.streamFolders(parentId: currentFolderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final folders = snapshot.data ?? [];
                if (folders.isEmpty) return const Center(child: Text('No hay carpetas aquí.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return Card(
                      key: ValueKey(folder.id),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.grey),
                        title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerFeed(
                                userProfile: userProfile,
                                currentFolderId: folder.id,
                                currentFolderName: folder.name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final supabaseService = SupabaseService(
      adminApiKey: Config.adminApiKey.isEmpty ? null : Config.adminApiKey,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await supabaseService.signOut();
              Navigator.pop(dialogContext);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
