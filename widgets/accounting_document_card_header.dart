class AccountingDocumentCardHeader extends StatelessWidget {
  final AccountingDocumentMobileDTO document;
  final bool showExpandableIcon;
  final bool isExpanded;
  final Widget? customHeader;

  const AccountingDocumentCardHeader({
    super.key,
    required this.document,
    required this.showExpandableIcon,
    required this.isExpanded,
    required this.customHeader,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations locale = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              customHeader ?? _buildHeaderTitle(),
              if (showExpandableIcon) _buildChevronIcon(),
            ],
          ),
          const SizedBox(height: 12.0),
          const Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppTheme.gray100,
                  height: 10.0,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Row(
                children: [
                  _buildPaymentStatusIcon(),
                  const SizedBox(width: 6.0),
                  _buildPaymentStatusText(locale),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildAmountToPayText(context, locale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              document.title,
              style: TextStyle(
                color: const Color(0xff1D2939),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChevronIcon() {
    return Builder(
      builder: (context) => Transform.rotate(
        angle: isExpanded ? 0 : pi,
        child: Assets.icons.chevronUp.svg(
          height: 24.h,
          width: 24.h,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusIcon() {
    final double iconSize = 24.h;

    if (document.hasNegativeTotalAmount || document.isOverpaid) {
      return Assets.icons.alertCircle.svg(height: iconSize, width: iconSize);
    }

    if (document.isPaid) {
      return Assets.icons.successCircle.svg(height: iconSize, width: iconSize);
    }

    if (document.isFullyUnpaidBeforeDeadline || document.isPartiallyUnpaidBeforeDeadline) {
      return Assets.icons.infoCircle.svg(height: iconSize, width: iconSize);
    }

    if (document.isFullyUnpaidAfterDeadline || document.isPartiallyUnpaidAfterDeadline) {
      return Assets.icons.warningCircle.svg(height: iconSize, width: iconSize);
    }

    return const SizedBox.shrink();
  }

  Widget _buildPaymentStatusText(AppLocalizations locale) {
    late final String text;
    late final Color statusColor;

    if (document.hasNegativeTotalAmount || document.isOverpaid) {
      text = locale.paymentOverpaid;
      statusColor = AppTheme.warning500;
    } else if (document.isPaid) {
      text = locale.paid;
      statusColor = AppTheme.success600;
    } else if (document.isFullyUnpaidBeforeDeadline || document.isPartiallyUnpaidBeforeDeadline) {
      text = locale.remainsToBePaid;
      statusColor = AppTheme.lightBlue500;
    } else if (document.isFullyUnpaidAfterDeadline || document.isPartiallyUnpaidAfterDeadline) {
      text = locale.unpaid;
      statusColor = AppTheme.error500;
    } else {
      text = '';
      statusColor = Colors.black;
    }

    return Text(
      text,
      style: TextStyle(
        color: statusColor,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAmountToPayText(BuildContext context, AppLocalizations locale) {
    final TextStyle style = TextStyle(
      color: const Color(0xff475467),
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
    );

    final num total = document.totalAmount ?? 0;
    final num totalPaid = document.totalAmountPaid ?? 0;

    if (document.hasNegativeTotalAmount) {
      return PaymentsLocalizedCurrencyText(
        (-total).currencyTwoDecimalDigitsFormat(context),
        style: style,
      );
    }

    if (document.isPaid) {
      return PaymentsLocalizedCurrencyText(
        (total + (totalPaid - total)).currencyTwoDecimalDigitsFormat(context),
        style: style,
      );
    }

    if (document.isOverpaid) {
      return PaymentsLocalizedCurrencyText(
        total.currencyTwoDecimalDigitsFormat(context),
        style: style,
      );
    }

    if (document.isFullyUnpaidBeforeDeadline || document.isFullyUnpaidAfterDeadline) {
      return PaymentsLocalizedCurrencyText(
        total.currencyTwoDecimalDigitsFormat(context),
        style: style,
      );
    }

    if (document.isPartiallyUnpaidBeforeDeadline || document.isPartiallyUnpaidAfterDeadline) {
      return Consumer(
        builder: (context, ref, _) {
          final String? currency = ref.watch(defaultCurrencyByHomeAccountProvider).valueOrNull;

          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${(total - totalPaid).currencyTwoDecimalDigitsFormat(context)} ${currency ?? ''}',
                  style: style,
                ),
                TextSpan(
                  text: ' ${locale.from} ',
                  style: TextStyle(
                    color: const Color(0xff667085),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${total.currencyTwoDecimalDigitsFormat(context)} ${currency ?? ''}',
                  style: style,
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
