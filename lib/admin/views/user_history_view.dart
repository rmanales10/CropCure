import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cropcure/admin/controller.dart';
import 'package:cropcure/admin/widgets/user_card.dart';
import 'package:cropcure/admin/views/user_detail_view.dart';

class UserHistoryView extends StatefulWidget {
  final Controller controller;

  const UserHistoryView({super.key, required this.controller});

  @override
  State<UserHistoryView> createState() => _UserHistoryViewState();
}

class _UserHistoryViewState extends State<UserHistoryView> {
  String _userSearchQuery = '';
  Timer? _debounceTimer;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _userSearchQuery = value.toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for loading, selectedUserId, and users list changes
    return Obx(() {
      if (widget.controller.isLoadingUsers.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      }

      // Access selectedUserId.value to trigger reactivity
      final selectedId = widget.controller.selectedUserId.value;
      if (selectedId.isNotEmpty) {
        return UserDetailView(controller: widget.controller);
      }

      return _buildUserList();
    });
  }

  Widget _buildUserList() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Scan History',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'View individual user scan statistics',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 30),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                suffixIcon:
                    _userSearchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _userSearchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // Users List - Optimized with ListView.builder
          Obx(() {
            // Compute filtered users here to access reactive list
            final filteredUsers =
                widget.controller.users.where((user) {
                  if (_userSearchQuery.isEmpty) return true;
                  final name =
                      (user['fullname'] ?? '').toString().toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  return name.contains(_userSearchQuery) ||
                      email.contains(_userSearchQuery);
                }).toList();

            if (filteredUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userSearchQuery.isEmpty
                            ? 'No users found'
                            : 'No users match your search',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                return UserCard(
                  key: ValueKey(filteredUsers[index]['uid']),
                  user: filteredUsers[index],
                  controller: widget.controller,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
