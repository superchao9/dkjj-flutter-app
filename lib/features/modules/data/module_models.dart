import 'package:flutter/material.dart';

enum ModulePageKind {
  generic,
  inspectionCollection,
  inspectionAnalysis,
  inspectionRoute,
  inspectionArea,
  bpmCenter,
}

enum ModuleValueType {
  text,
  number,
  multiline,
}

class ModuleFieldDefinition {
  const ModuleFieldDefinition({
    required this.key,
    required this.label,
    this.type = ModuleValueType.text,
    this.required = false,
    this.readOnly = false,
  });

  final String key;
  final String label;
  final ModuleValueType type;
  final bool required;
  final bool readOnly;
}

class ModuleDefinition {
  const ModuleDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.pageKind = ModulePageKind.generic,
    this.pagePath,
    this.listPath,
    this.detailPath,
    this.createPath,
    this.updatePath,
    this.deletePath,
    this.submitPath,
    this.pageResult = true,
    this.searchFields = const [],
    this.titleFields = const [],
    this.displayFields = const [],
    this.editableFields = const [],
    this.supportsApproval = false,
  });

  final String id;
  final String title;
  final String category;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ModulePageKind pageKind;
  final String? pagePath;
  final String? detailPath;
  final String? createPath;
  final String? updatePath;
  final String? deletePath;
  final String? submitPath;
  final String? listPath;
  final bool pageResult;
  final List<ModuleFieldDefinition> searchFields;
  final List<String> titleFields;
  final List<ModuleFieldDefinition> displayFields;
  final List<ModuleFieldDefinition> editableFields;
  final bool supportsApproval;
}

class DynamicPageResult {
  const DynamicPageResult({
    required this.total,
    required this.list,
  });

  final int total;
  final List<Map<String, dynamic>> list;
}
