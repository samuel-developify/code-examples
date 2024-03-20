import 'dart:math';

import 'package:beit_api_accounting_service/api.dart';
import 'package:beit_app/core/enums/delivery_category_enum.dart';
import 'package:beit_app/core/extensions/num_extensions.dart';
import 'package:beit_app/core/settings/app_theme.dart';
import 'package:beit_app/features/payments/widgets/payments_localized_currency_text.dart';
import 'package:beit_app/gen/assets.gen.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expandable/expandable.dart';
import 'package:beit_app/flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class AccountingDocumentCardItems extends ConsumerStatefulWidget {
  final List<AccountingDocumentItemDTO> items;

  const AccountingDocumentCardItems(this.items, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PaymentItemsExpandableCardState();
}

class _PaymentItemsExpandableCardState extends ConsumerState<AccountingDocumentCardItems> {
  AppLocalizations get locale => AppLocalizations.of(context)!;

  late final ExpandableController controller = ExpandableController()
    ..expanded = false
    ..addListener(() {
      setState(() {});
    });

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      controller: controller,
      theme: const ExpandableThemeData(
        hasIcon: false,
        tapBodyToCollapse: false,
        tapBodyToExpand: false,
        tapHeaderToExpand: true,
        inkWellBorderRadius: BorderRadius.all(Radius.circular(AppTheme.cardBorderRadius)),
      ),
      header: _buildShowDocumentsHeader(),
      collapsed: const SizedBox.shrink(),
      expanded: Column(
        children: widget.items.map((document) {
          final bool isLast = widget.items.last == document;

          if (isLast) {
            return ScrollOnExpand(child: _buildItem(document));
          }

          return _buildItem(document);
        }).toList(),
      ),
    );
  }

  Widget _buildShowDocumentsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.expanded ? locale.hideDocumentItems : locale.viewDocumentItems,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8.0),
          Transform.rotate(
            angle: controller.expanded ? 0 : pi,
            child: Assets.icons.chevronUp.svg(
              height: 20.h,
              width: 20.h,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(AccountingDocumentItemDTO item) {
    final DeliveryCategoryEnum? delivery = DeliveryCategoryEnum.values
        .firstWhereOrNull((d) => d.name == item.accountingCategoryCode?.value);

    if (delivery == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  constraints: BoxConstraints.tight(Size.square(40.h)),
                  decoration: BoxDecoration(
                    color: delivery.asBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: delivery.asIcon?.svg(
                            height: 24.h,
                            width: 24.h,
                          ) ??
                          const Placeholder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Flexible(
                  child: Text(
                    item.description,
                    style: TextStyle(
                      color: const Color(0xff475467),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20.0),
          PaymentsLocalizedCurrencyText(
            item.amount.currencyFormat(context),
            style: TextStyle(
              color: const Color(0xff101828),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
