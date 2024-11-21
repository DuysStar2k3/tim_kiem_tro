import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import 'room_location_detail_screen.dart';
import '../../../../models/comment_model.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0;
  double _userRating = 0;
  bool _isFavorite = false;
  final int _initialCommentCount = 3;
  bool _showAllComments = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() {
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser != null) {
      setState(() {
        _isFavorite = widget.room.favoriteBy.contains(currentUser.id);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthController>().currentUser;
    final canRate =
        currentUser != null && !widget.room.ratedBy.contains(currentUser.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với ảnh phòng
          _buildSliverAppBar(),

          // Nội dung chi tiết
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail ảnh
                if (widget.room.images.length > 1) _buildImageThumbnails(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header với tiêu đề và nút yêu thích
                      _buildHeader(currentUser?.id),

                      const SizedBox(height: 16),
                      // Thông tin cơ bản
                      _buildBasicInfo(),

                      const SizedBox(height: 24),
                      // Địa chỉ
                      _buildLocationSection(),

                      const SizedBox(height: 24),
                      // Tiện ích
                      _buildUtilities(),

                      const SizedBox(height: 24),
                      // Mô tả
                      _buildDescription(),

                      const SizedBox(height: 24),
                      // Đánh giá
                      if (canRate) _buildRatingSection(),

                      const SizedBox(height: 24),
                      // Bình luận
                      _buildCommentSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.room.images.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return Image.network(
                  widget.room.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                );
              },
            ),
            // Indicator số ảnh
            if (widget.room.images.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${widget.room.images.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnails() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.room.images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentPage == index
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  widget.room.images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String? userId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.room.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.room.rating.toStringAsFixed(1)} (${widget.room.ratingCount})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (userId != null)
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () => _toggleFavorite(userId),
          ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.attach_money,
                title: 'Giá thuê',
                value: '${widget.room.price.toStringAsFixed(0)} VNĐ/tháng',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.square_foot,
                title: 'Diện tích',
                value: '${widget.room.area} m²',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.account_balance_wallet,
                title: 'Đặt cọc',
                value: '${widget.room.deposit.toStringAsFixed(0)} VNĐ',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.people,
                title: 'Số người ở',
                value: '${widget.room.maxTenants} người',
                subtitle: 'Giới tính: ${widget.room.gender}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Địa chỉ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RoomLocationDetailScreen(room: widget.room),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.room.address,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.room.hasParking)
              _buildUtilityItem(Icons.motorcycle, 'Chỗ để xe'),
            if (widget.room.hasWifi) _buildUtilityItem(Icons.wifi, 'Wifi'),
            if (widget.room.hasAC) _buildUtilityItem(Icons.ac_unit, 'Điều hòa'),
            if (widget.room.hasFridge)
              _buildUtilityItem(Icons.kitchen, 'Tủ lạnh'),
            if (widget.room.hasWasher)
              _buildUtilityItem(Icons.local_laundry_service, 'Máy giặt'),
            if (widget.room.hasPrivateBathroom)
              _buildUtilityItem(Icons.wc, 'WC riêng'),
            if (widget.room.hasKitchen)
              _buildUtilityItem(Icons.restaurant, 'Bếp'),
            if (widget.room.hasFreedom)
              _buildUtilityItem(Icons.lock_open, 'Tự do'),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả chi tiết',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.room.description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Bạn nghĩ sao về phòng trọ này?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 40,
                unratedColor: Colors.grey[300],
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _userRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _userRating == 0 ? null : () => _submitRating(),
                  icon: const Icon(Icons.star),
                  label: const Text('Gửi đánh giá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitRating() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Xác nhận đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc chắn muốn đánh giá phòng trọ này?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  color: index < _userRating 
                      ? Colors.amber 
                      : Colors.grey[300],
                  size: 24,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '${_userRating} sao',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu ý: Bạn chỉ được đánh giá một lần',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<RoomController>().rateRoom(
        widget.room.id,
        userId,
        _userRating,
      );

      if (!mounted) return;

      // Hiển thị dialog thành công
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[400],
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đánh giá thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cảm ơn bạn đã đánh giá phòng trọ này',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      // Cập nhật UI
      setState(() {
        _userRating = 0;
      });
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCommentSection() {
    final currentUser = context.read<AuthController>().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bình luận
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bình luận',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentUser != null)
              TextButton.icon(
                onPressed: () => _showCommentInput(currentUser.id),
                icon: const Icon(Icons.add_comment),
                label: const Text('Viết bình luận'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Stream bình luận
        StreamBuilder<List<CommentModel>>(
          stream: context.read<RoomController>().getRoomComments(widget.room.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Đã có lỗi xảy ra',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data!;
            final parentComments = comments
                .where((c) => c.parentId == null)
                .toList();

            if (comments.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, 
                      size: 48, 
                      color: Colors.grey[400]
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có bình luận nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // Lọc số lượng bình luận hiển thị
            final displayedComments = _showAllComments 
                ? parentComments 
                : parentComments.take(_initialCommentCount).toList();

            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedComments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildCommentItem(
                      displayedComments[index],
                      comments.where((c) => 
                        c.parentId == displayedComments[index].id).toList(),
                      currentUser?.id,
                    );
                  },
                ),

                // Nút xem thêm
                if (parentComments.length > _initialCommentCount && !_showAllComments)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllComments = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xem thêm ${parentComments.length - _initialCommentCount} bình luận',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, 
                            color: Colors.grey[800]
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(
    CommentModel comment,
    List<CommentModel> replies,
    String? currentUserId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bình luận chính
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với avatar và tên
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: comment.userAvatar != null
                          ? NetworkImage(comment.userAvatar!)
                          : null,
                      child: comment.userAvatar == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName ?? 'Người dùng',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(comment.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Nội dung bình luận
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    comment.content,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

                // Actions
                Row(
                  children: [
                    _buildActionButton(
                      icon: comment.likes.contains(currentUserId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: comment.likes.length.toString(),
                      color: comment.likes.contains(currentUserId)
                          ? Colors.red
                          : Colors.grey[600]!,
                      onPressed: currentUserId != null
                          ? () => _likeComment(comment.id, currentUserId)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.reply,
                      label: 'Trả lời',
                      color: Colors.grey[600]!,
                      onPressed: currentUserId != null
                          ? () => _showReplyInput(comment.id)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Phần replies
          if (replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 32),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: replies.map((reply) => 
                  _buildReplyItem(reply, currentUserId)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildReplyItem(CommentModel reply, String? currentUserId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: reply.userAvatar != null
                      ? NetworkImage(reply.userAvatar!)
                      : null,
                  child: reply.userAvatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.userName ?? 'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatDate(reply.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                reply.content,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: currentUserId != null
                      ? () => _likeComment(reply.id, currentUserId)
                      : null,
                  icon: Icon(
                    reply.likes.contains(currentUserId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 14,
                    color: reply.likes.contains(currentUserId)
                        ? Colors.red
                        : Colors.grey,
                  ),
                  label: Text(
                    reply.likes.length.toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(String userId, {String? parentId}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: parentId != null ? 'Trả lời bình luận...' : 'Viết bình luận...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppColors.primary,
            onPressed: () {
              if (_commentController.text.trim().isNotEmpty) {
                context.read<RoomController>().addRoomComment(
                  widget.room.id,
                  userId,
                  _commentController.text.trim(),
                  parentId: parentId,
                );
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReplyInput(String parentId) {
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _buildCommentInput(currentUser.id, parentId: parentId),
          ),
        );
      },
    );
  }

  Future<void> _likeComment(String commentId, String userId) async {
    await context.read<RoomController>().toggleCommentLike(commentId, userId);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUtilityItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  void _toggleFavorite(String userId) {
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser != null) {
      context
          .read<RoomController>()
          .toggleFavorite(widget.room.id, currentUser.id);
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall(widget.room.phone),
              icon: const Icon(Icons.phone),
              label: const Text('Liên hệ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm phương thức hiển thị dialog nhập bình luận
  void _showCommentInput(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Tiêu đề
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Viết bình luận',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Ô nhập bình luận
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập bình luận của bạn...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                    autofocus: true,
                  ),
                ),

                // Nút gửi
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_commentController.text.trim().isNotEmpty) {
                          context.read<RoomController>().addRoomComment(
                            widget.room.id,
                            userId,
                            _commentController.text.trim(),
                          );
                          _commentController.clear();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gửi bình luận',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
