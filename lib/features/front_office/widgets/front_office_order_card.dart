import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../domain/models.dart';

/// Front Office Customer Order Card
class FrontOfficeOrderCard extends StatelessWidget {
  const FrontOfficeOrderCard({
    super.key,
    required this.index,
    required this.order,
    required this.onTap,
  });

  final int index;
  final CustomerOrder order;
  final VoidCallback onTap;

  static Color getStatusColor(OrderStatus status) => switch (status) {
    OrderStatus.pending => AppColors.danger,
    OrderStatus.inWorkshop => AppColors.goldDark,
    OrderStatus.ready => AppColors.emerald,
    OrderStatus.dispatched => const Color(0xFF2C3E50),
    OrderStatus.delivered => AppColors.emeraldDark,
    OrderStatus.cancelled => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = order.isBlocked
        ? AppColors.danger
        : getStatusColor(order.status);

    return CommonCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      borderRadius: BorderRadius.circular(10.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$index. ${order.id} · ${order.clientFirmName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: AppColors.ink,
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.isBlocked
                      ? 'ON HOLD'
                      : order.status == OrderStatus.inWorkshop
                      ? 'in progress'
                      : order.status == OrderStatus.ready
                      ? 'complete'
                      : order.status == OrderStatus.pending
                      ? 'delay'
                      : order.status.label.toLowerCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5.sp,
                  ),
                ),
              ),
            ],
          ),
          if (order.isBlocked) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pause_circle_filled_rounded,
                    color: AppColors.danger,
                    size: 12.sp,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      'ON CRITICAL HOLD: ${order.blockedReason ?? "Stage blocked by workshop"}',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 3.h),
          Row(
            children: [
              Text(
                'Stage: ${order.currentWorkshopStage.isNotEmpty ? order.currentWorkshopStage : 'Unassigned'}',
                style: TextStyle(
                  color: order.currentWorkshopStage.isNotEmpty &&
                          order.currentWorkshopStage.toLowerCase() != 'unassigned'
                      ? AppColors.emeraldDark
                      : AppColors.muted,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5.w),
              Text('•', style: TextStyle(color: AppColors.muted, fontSize: 9.5.sp)),
              SizedBox(width: 5.w),
              Text(
                '${order.promiseDate.isEmpty ? '' : 'Due: ${order.promiseDate} · '}${order.itemsCount} pcs',
                style: TextStyle(color: AppColors.muted, fontSize: 10.5.sp),
              ),
            ],
          ),
          if (order.designs.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: [
                ...order.designs.take(3).map((d) {
                  final name = d.displayName;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${d.quantity} pcs',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text('·', style: TextStyle(color: AppColors.muted, fontSize: 9.5.sp)),
                        SizedBox(width: 3.w),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 150.w),
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (order.designs.length > 3)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '+${order.designs.length - 3} more',
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (order.itemsSummary.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              order.itemsSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
