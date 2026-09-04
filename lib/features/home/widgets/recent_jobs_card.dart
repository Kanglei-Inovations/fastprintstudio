import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/print_history_item.dart';
import '../theme/dashboard_palette.dart';

class RecentJobsCard extends StatelessWidget {
  final DashboardPalette palette;
  final List<PrintHistoryItem> history;
  final VoidCallback onViewAll;

  const RecentJobsCard({
    super.key,
    required this.palette,
    required this.history,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Generate realistic jobs from live history or sample jobs matching the reference mockup
    final displayJobs = history.isNotEmpty
        ? history.take(5).map((h) {
            return _JobRowData(
              jobId: '#FP${1000 + history.indexOf(h)}',
              name: h.serviceName,
              serviceTag: h.serviceName.contains('Aadhaar') || h.serviceName.contains('Card')
                  ? 'ID Card'
                  : (h.serviceName.contains('Passport')
                      ? 'Passport'
                      : (h.serviceName.contains('Photo') ? '4R Print' : 'Document')),
              size: h.paperName.isNotEmpty ? h.paperName : '4R (4 × 6)',
              copies: h.copiesCount > 0 ? h.copiesCount : 1,
              time: DateFormat('d MMM, hh:mm a').format(h.timestamp),
              isPrinted: true,
              icon: h.serviceName.contains('Aadhaar') || h.serviceName.contains('Card')
                  ? Icons.badge_outlined
                  : (h.serviceName.contains('Passport')
                      ? Icons.portrait_rounded
                      : (h.serviceName.contains('Photo') ? Icons.photo_outlined : Icons.description_outlined)),
              accentColor: h.serviceName.contains('Aadhaar')
                  ? palette.blue
                  : (h.serviceName.contains('Passport')
                      ? palette.green
                      : (h.serviceName.contains('Photo') ? palette.orange : palette.purple)),
            );
          }).toList()
        : [
            _JobRowData(
              jobId: '#FP1024',
              name: 'ID Card - Front & Back',
              serviceTag: 'ID Card',
              size: '4R (4 × 6)',
              copies: 2,
              time: '31 Aug, 02:31 PM',
              isPrinted: true,
              icon: Icons.badge_outlined,
              accentColor: palette.blue,
            ),
            _JobRowData(
              jobId: '#FP1023',
              name: 'Passport Photo - 8 Copies',
              serviceTag: 'Passport',
              size: '4R (4 × 6)',
              copies: 1,
              time: '31 Aug, 01:45 PM',
              isPrinted: true,
              icon: Icons.portrait_rounded,
              accentColor: palette.green,
            ),
            _JobRowData(
              jobId: '#FP1022',
              name: 'Document - Invoice',
              serviceTag: 'Document',
              size: 'A4',
              copies: 1,
              time: '31 Aug, 12:18 PM',
              isPrinted: true,
              icon: Icons.description_outlined,
              accentColor: palette.purple,
            ),
            _JobRowData(
              jobId: '#FP1021',
              name: '4R Photo - Mixed',
              serviceTag: '4R Print',
              size: '4R (4 × 6)',
              copies: 2,
              time: '31 Aug, 11:02 AM',
              isPrinted: true,
              icon: Icons.photo_outlined,
              accentColor: palette.orange,
            ),
            _JobRowData(
              jobId: '#FP1020',
              name: 'PAN Card - Front',
              serviceTag: 'ID Card',
              size: '4R (4 × 6)',
              copies: 1,
              time: '31 Aug, 10:25 AM',
              isPrinted: false,
              icon: Icons.credit_card_rounded,
              accentColor: palette.red,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Printed Jobs',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your latest printed jobs in shop queue',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View All →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.pillBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Job Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Service', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Size', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Copies', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayJobs.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: palette.divider),
            itemBuilder: (context, index) {
              final job = displayJobs[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Job Name + Icon
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: job.accentColor.withValues(alpha: palette.isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(job.icon, size: 13, color: job.accentColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              job.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Service Pill
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: job.accentColor.withValues(alpha: palette.isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            job.serviceTag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: job.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Size
                    Expanded(
                      flex: 2,
                      child: Text(
                        job.size,
                        style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      ),
                    ),

                    // Copies
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${job.copies}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                    ),

                    // Time
                    Expanded(
                      flex: 3,
                      child: Text(
                        job.time,
                        style: TextStyle(fontSize: 10, color: palette.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Status Pill
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: job.isPrinted
                                ? palette.green.withValues(alpha: palette.isDark ? 0.15 : 0.1)
                                : palette.red.withValues(alpha: palette.isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            job.isPrinted ? 'Printed' : 'Cancelled',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: job.isPrinted ? palette.green : palette.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JobRowData {
  final String jobId;
  final String name;
  final String serviceTag;
  final String size;
  final int copies;
  final String time;
  final bool isPrinted;
  final IconData icon;
  final Color accentColor;

  _JobRowData({
    required this.jobId,
    required this.name,
    required this.serviceTag,
    required this.size,
    required this.copies,
    required this.time,
    required this.isPrinted,
    required this.icon,
    required this.accentColor,
  });
}
