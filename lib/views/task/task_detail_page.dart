import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestiontaches/models/task.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;
  final String projectTitle;
  final List<String> projectMembers;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.projectTitle,
    this.projectMembers = const [],
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late String _currentStatus;
  late TaskModel _task;
  String? _assigneeName;
  String? _assigneePhotoURL;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, dynamic>> _usersCache = {};

  final List<Map<String, String>> statusOptions = [
    {'value': 'todo', 'label': 'À faire', 'color': 'grey'},
    {'value': 'inprogress', 'label': 'En cours', 'color': 'indigo'},
    {'value': 'done', 'label': 'Terminé', 'color': 'green'},
  ];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _currentStatus = _task.status;
    if (_task.isCompleted) {
      _currentStatus = 'done';
    }
    _loadAllUsers();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    final Set<String> userIds = {};

    if (_task.assigneeId != null && _task.assigneeId!.isNotEmpty) {
      userIds.add(_task.assigneeId!);
    }

    for (final memberId in widget.projectMembers) {
      userIds.add(memberId);
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userIds.add(currentUser.uid);
    }

    for (final userId in userIds) {
      if (_usersCache.containsKey(userId)) continue;

      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _usersCache[userId] = {
              'name': data['name'] ?? data['displayName'] ?? 'Utilisateur',
              'photoURL': data['photoURL'] ?? '',
              'email': data['email'] ?? '',
            };
          });

          if (userId == _task.assigneeId) {
            setState(() {
              _assigneeName = _usersCache[userId]!['name'];
              _assigneePhotoURL = _usersCache[userId]!['photoURL'];
            });
          }
        }
      } catch (e) {
        print('❌ Erreur chargement utilisateur $userId: $e');
      }
    }
  }

  Widget _buildAvatar(String? userId, {double size = 36}) {
    final user = userId != null ? _usersCache[userId] : null;
    final photoURL = user?['photoURL'] as String? ?? '';

    final bool hasPhoto = photoURL.isNotEmpty && File(photoURL).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.file(
                File(photoURL),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400);
                },
              ),
            )
          : Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400),
    );
  }

  String _getUserName(String? userId) {
    if (userId == null) return 'Inconnu';
    return _usersCache[userId]?['name'] as String? ?? 'Utilisateur';
  }

  Future<void> _changeAssignee() async {
    final membersToShow = widget.projectMembers.isNotEmpty
        ? widget.projectMembers
        : [_task.assigneeId ?? ''].where((id) => id.isNotEmpty).toList();

    for (final memberId in membersToShow) {
      if (!_usersCache.containsKey(memberId)) {
        try {
          final doc = await _firestore.collection('users').doc(memberId).get();
          if (doc.exists) {
            final data = doc.data()!;
            setState(() {
              _usersCache[memberId] = {
                'name': data['name'] ?? data['displayName'] ?? 'Utilisateur',
                'photoURL': data['photoURL'] ?? '',
                'email': data['email'] ?? '',
              };
            });
          }
        } catch (e) {
          print('❌ Erreur chargement membre $memberId: $e');
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Assigner à',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...membersToShow.map((memberId) {
                  final member = _usersCache[memberId];
                  final bool isSelected = memberId == _task.assigneeId;

                  return ListTile(
                    leading: _buildAvatar(memberId, size: 40),
                    title: Text(
                      member?['name'] ?? 'Utilisateur',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      member?['email'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF6B4EFF))
                        : null,
                    onTap: () async {
                      try {
                        await _firestore.collection('tasks').doc(_task.id).update({
                          'assigneeId': memberId,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        setState(() {
                          _task = _task.copyWith(assigneeId: memberId);
                          _assigneeName = _getUserName(memberId);
                          _assigneePhotoURL = _usersCache[memberId]?['photoURL'] as String?;
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Assigné à ${_getUserName(memberId)}'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? 'anonymous';
    final currentUserName = _getUserName(currentUserId);

    try {
      await _firestore
          .collection('tasks')
          .doc(_task.id)
          .collection('comments')
          .add({
        'text': text,
        'authorId': currentUserId,
        'authorName': currentUserName,
        'createdAt': Timestamp.now(),
        'mentions': _extractMentions(text),
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
      );
    }
  }

  List<String> _extractMentions(String text) {
    final matches = RegExp(r'@(\w+)').allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  String get _statusLabel {
    switch (_currentStatus) {
      case 'done':
        return 'Terminé';
      case 'inprogress':
        return 'En cours';
      case 'todo':
      default:
        return 'À faire';
    }
  }

  Color get _statusColor {
    switch (_currentStatus) {
      case 'done':
        return const Color(0xFF10B981);
      case 'inprogress':
        return const Color(0xFF6B4EFF);
      case 'todo':
      default:
        return Colors.grey.shade600;
    }
  }

  Color get _statusBgColor {
    switch (_currentStatus) {
      case 'done':
        return const Color(0xFFD1FAE5);
      case 'inprogress':
        return const Color(0xFFE8E4FF);
      case 'todo':
      default:
        return Colors.grey.shade100;
    }
  }

  bool get _isLate {
    if (_task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(_task.dueDate!.year, _task.dueDate!.month, _task.dueDate!.day);
    return due.isBefore(today);
  }

  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Changer le statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...statusOptions.map((status) {
                  final isSelected = _currentStatus == status['value'];
                  final color = status['color'] == 'green'
                      ? const Color(0xFF10B981)
                      : status['color'] == 'indigo'
                          ? const Color(0xFF6B4EFF)
                          : Colors.grey.shade600;

                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      status['label']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: color)
                        : null,
                    onTap: () {
                      setState(() {
                        _currentStatus = status['value']!;
                        _task = _task.copyWith(
                          status: _currentStatus,
                          isCompleted: _currentStatus == 'done',
                        );
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _task.priorityColor as Color? ?? Colors.orange;
    final priorityLabel = _task.priority;
    final date = _task.dueDate != null ? DateFormat('d MMM').format(_task.dueDate!) : 'Non définie';
    final createdAt = _task.createdAt != null
        ? DateFormat('d MMMM yyyy', 'fr_FR').format(_task.createdAt)
        : 'Date inconnue';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ❌ Icône de modification supprimée
          // Gardé seulement la suppression
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black54),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer la tâche'),
                  content: const Text('Voulez-vous vraiment supprimer cette tâche ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, {'deleted': true});
                      },
                      child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.projectTitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _changeStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _statusColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _task.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _task.description ?? 'Aucune description',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          'Assigné à',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAvatar(_task.assigneeId, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              _assigneeName ?? 'Chargement...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _changeAssignee,
                              child: Text(
                                'Modifier',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF6B4EFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          'Échéance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isLate && _currentStatus != 'done') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'En retard',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[400],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          'Priorité',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          'Créée le',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          createdAt,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('tasks')
                    .doc(_task.id)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  }

                  final comments = snapshot.data?.docs ?? [];
                  final commentCount = comments.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commentaires ($commentCount)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (comments.isEmpty)
                        Text(
                          'Aucun commentaire. Soyez le premier !',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...comments.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final authorId = data['authorId'] as String? ?? '';
                          final createdAt = data['createdAt'] as Timestamp?;
                          final timeAgo = createdAt != null
                              ? _formatTimeAgo(createdAt.toDate())
                              : 'maintenant';

                          if (authorId.isNotEmpty && !_usersCache.containsKey(authorId)) {
                            _firestore.collection('users').doc(authorId).get().then((userDoc) {
                              if (userDoc.exists && mounted) {
                                final userData = userDoc.data()!;
                                setState(() {
                                  _usersCache[authorId] = {
                                    'name': userData['name'] ?? userData['displayName'] ?? 'Anonyme',
                                    'photoURL': userData['photoURL'] ?? '',
                                    'email': userData['email'] ?? '',
                                  };
                                });
                              }
                            });
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildComment(
                              authorId: authorId,
                              time: timeAgo,
                              comment: data['text'] ?? '',
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildAvatar(FirebaseAuth.instance.currentUser?.uid, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.alternate_email,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_file,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendComment,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('d MMM').format(date);
  }

  Widget _buildComment({
    required String authorId,
    required String time,
    required String comment,
  }) {
    final authorName = _getUserName(authorId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(authorId, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  children: _buildCommentText(comment),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildCommentText(String text) {
    final List<TextSpan> spans = [];
    final parts = text.split(RegExp(r'(@\w+)'));
    final matches = RegExp(r'@\w+').allMatches(text).map((m) => m.group(0)).toList();

    int matchIndex = 0;
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (matchIndex < matches.length && i < parts.length - 1) {
        spans.add(TextSpan(
          text: matches[matchIndex],
          style: TextStyle(
            color: Colors.indigo[400],
            fontWeight: FontWeight.w600,
          ),
        ));
        matchIndex++;
      }
    }

    return spans;
  }
}