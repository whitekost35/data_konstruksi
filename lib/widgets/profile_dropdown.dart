import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class ProfileDropdown extends StatelessWidget {
  const ProfileDropdown({super.key});

  void _pickImage(ProjectProvider provider) {
    final uploadInput = web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.length > 0) {
        final reader = web.FileReader();
        reader.readAsArrayBuffer(files.item(0)!);
        reader.onLoadEnd.listen((e) {
          final result = reader.result;
          if (result != null) {
            final bytes = (result as JSArrayBuffer).toDart.asUint8List();
            provider.updateProfilePhoto(bytes);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final profile = provider.userProfile;

    if (profile == null) return const SizedBox();

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _pickImage(provider),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                  child: profile.photoUrl == null 
                    ? const Icon(CupertinoIcons.person_fill, size: 50, color: Colors.grey) 
                    : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Nama', profile.name),
          const SizedBox(height: 16),
          _buildInfoRow('Status', profile.status),
          const SizedBox(height: 16),
          _buildInfoRow('Alamat', profile.address),
          const SizedBox(height: 16),
          _buildInfoRow('Kontak', profile.contact),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                provider.clearProfile();
                context.read<AuthProvider>().logout();
              },
              borderRadius: BorderRadius.circular(16),
              hoverColor: Colors.redAccent.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.power, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 16),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
          ),
        ),
        const Text(':  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(
          child: Text(
            value, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)
          ),
        ),
      ],
    );
  }
}
