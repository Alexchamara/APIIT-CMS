import 'package:flutter/material.dart';
import 'package:apiit_cms/features/support/domain/models/support_ticket_model.dart';
import 'package:apiit_cms/features/support/data/support_ticket_repository.dart';
import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:intl/intl.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  SupportTicketModel? _ticket;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final ticketFuture = SupportTicketRepository.getTicketById(widget.ticketId);
      final userFuture = AuthRepository.getCurrentUserModel();
      
      final results = await Future.wait([ticketFuture, userFuture]);
      
      setState(() {
        _ticket = results[0] as SupportTicketModel?;
        _currentUser = results[1] as UserModel?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ticket: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await SupportTicketRepository.addMessage(
        ticketId: widget.ticketId,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      
      // Reload ticket to get updated messages
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Future<void> _updateStatus(TicketStatus newStatus) async {
    try {
      await SupportTicketRepository.updateTicketStatus(
        ticketId: widget.ticketId,
        status: newStatus,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ticket Not Found',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Ticket not found or you don\'t have permission to view it'),
        ),
      );
    }

    final isAdmin = _currentUser?.userType == UserType.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticket #${_ticket!.ticketId.substring(0, 8)}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isAdmin)
            PopupMenuButton<TicketStatus>(
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TicketStatus.pending,
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Mark as Pending'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: TicketStatus.resolved,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as Resolved'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: TicketStatus.closed,
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Mark as Closed'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ticket!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_ticket!.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _ticket!.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isAdmin) ...[
                  Text(
                    'Created by: ${_ticket!.lecturerName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      _getPriorityIcon(_ticket!.priority),
                      size: 16,
                      color: _getPriorityColor(_ticket!.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${_ticket!.priority.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getPriorityColor(_ticket!.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(_ticket!.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _ticket!.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Admin Update Status Section
          if (isAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_ticket!.status != TicketStatus.resolved)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(TicketStatus.resolved),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Mark as Resolved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (_ticket!.status != TicketStatus.resolved && _ticket!.status != TicketStatus.closed)
                        const SizedBox(width: 8),
                      if (_ticket!.status != TicketStatus.closed)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(TicketStatus.closed),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Mark as Closed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (_ticket!.status == TicketStatus.resolved || _ticket!.status == TicketStatus.closed)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(TicketStatus.pending),
                            icon: const Icon(Icons.schedule, size: 18),
                            label: const Text('Reopen Ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _ticket!.messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _ticket!.messages.length,
                    itemBuilder: (context, index) {
                      final message = _ticket!.messages[index];
                      return _MessageBubble(
                        message: message,
                        isCurrentUser: message.senderId == _currentUser?.uid,
                      );
                    },
                  ),
          ),

          // Message input
          if (_ticket!.status != TicketStatus.closed)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSendingMessage ? null : _sendMessage,
                    icon: _isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Icons.low_priority;
      case TicketPriority.medium:
        return Icons.priority_high;
      case TicketPriority.high:
        return Icons.warning;
      case TicketPriority.urgent:
        return Icons.error;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.medium:
        return Colors.orange;
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.urgent:
        return Colors.red[800]!;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool isCurrentUser;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isFromAdmin ? Colors.red : AppTheme.primary,
              child: Icon(
                message.isFromAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.isFromAdmin ? 'Admin' : message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: message.isFromAdmin ? Colors.red[800] : AppTheme.primary,
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
