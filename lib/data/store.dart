// Saved plans, kept on the device with shared_preferences. The web
// prototype keeps them in PostgreSQL; a phone app keeps them locally.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _key = 'agrismart.plans';
const maxSaved = 20;

Future<List<Map<String, dynamic>>> loadPlans() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List<dynamic>) e as Map<String, dynamic>];
  } catch (_) {
    return [];
  }
}

Future<void> savePlan(Map<String, dynamic> plan) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadPlans();
    // one entry per place: a new plan for the same place replaces the old one
    plans.removeWhere((p) => p['place'] == plan['place'] && p['isSample'] == plan['isSample']);
    plans.insert(0, plan);
    if (plans.length > maxSaved) plans.removeRange(maxSaved, plans.length);
    await prefs.setString(_key, jsonEncode(plans));
  } catch (_) {
    // saving is a convenience; the app works without it
  }
}

Future<void> deletePlan(String savedAt) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadPlans()..removeWhere((p) => p['savedAt'] == savedAt);
    await prefs.setString(_key, jsonEncode(plans));
  } catch (_) {}
}
