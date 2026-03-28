import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';

class ProjectState extends ChangeNotifier {
  static const _storageKey = 'flowforge_projects';
  static const _activeProjectKey = 'flowforge_active_project_id';

  List<Project> _projects = [];
  String? _activeProjectId;

  List<Project> get projects => List.unmodifiable(_projects);
  String? get activeProjectId => _activeProjectId;

  Project? get activeProject {
    if (_activeProjectId == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == _activeProjectId);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    await _loadState();
    if (_projects.isEmpty) {
      await _createDefaultProject();
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _projects = jsonList
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
      _activeProjectId = prefs.getString(_activeProjectKey);
      if (_activeProjectId != null &&
          !_projects.any((project) => project.id == _activeProjectId)) {
        _activeProjectId = null;
      }
    } catch (_) {
      _projects = [];
      _activeProjectId = null;
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _projects.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    if (_activeProjectId == null) {
      await prefs.remove(_activeProjectKey);
    } else {
      await prefs.setString(_activeProjectKey, _activeProjectId!);
    }
  }

  Future<void> _createDefaultProject() async {
    final defaultProject = Project(
      id: const Uuid().v4(),
      name: 'Personal',
      color: ProjectColors.blue,
      icon: ProjectIcons.folder,
      createdAt: DateTime.now(),
    );
    _projects = [defaultProject];
    _activeProjectId = null;
    await _saveState();
    notifyListeners();
  }

  Future<void> addProject({
    required String name,
    required Color color,
    required IconData icon,
    String? description,
    DateTime? deadline,
  }) async {
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      description: description,
      deadline: deadline,
    );
    _projects.add(project);
    await _saveState();
    notifyListeners();
  }

  Future<void> updateProject(Project updated) async {
    final index = _projects.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    _projects[index] = updated;
    await _saveState();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    if (_projects.length <= 1) return;
    _projects.removeWhere((p) => p.id == id);
    if (_activeProjectId == id) {
      _activeProjectId = null;
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> setActiveProject(String? id) async {
    if (id == null || _projects.any((p) => p.id == id)) {
      _activeProjectId = id;
      await _saveState();
      notifyListeners();
    }
  }

  Project? getProject(String? id) {
    if (id == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Project> getProjectsWithDeadline() {
    return _projects.where((p) => p.deadline != null).toList();
  }
}
