import 'package:beit_api_accounting_service/api.dart';
import 'package:beit_app/core/extensions/accounting_document_mobile_dto_extensions.dart';
import 'package:beit_app/core/extensions/accounting_document_payment_type_enum_extensions.dart';
import 'package:beit_app/core/extensions/datetime_extensions.dart';
import 'package:beit_app/core/settings/app_theme.dart';
import 'package:beit_app/core/widgets/custom_card.dart';
import 'package:beit_app/core/widgets/custom_loading_indicator.dart';
import 'package:beit_app/core/widgets/elevated_button_light.dart';
import 'package:beit_app/core/widgets/show_custom_bottom_sheet.dart';
import 'package:beit_app/features/payments/providers/payments_detail_provider.dart';
import 'package:beit_app/features/payments/screens/payment_qr_code_bottom_sheet.dart';
import 'package:beit_app/features/payments/widgets/accounting_document_card_header.dart';
import 'package:beit_app/features/payments/widgets/accounting_document_card_attachment.dart';
import 'package:beit_app/features/payments/widgets/accounting_document_card_items.dart';
import 'package:beit_app/features/refunds/screens/create_refund_bottom_sheet.dart';
import 'package:beit_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expandable/expandable.dart';
import 'package:beit_app/flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class AccountingDocumentCard extends ConsumerStatefulWidget {
  final AccountingDocumentMobileDTO document;
  final Widget? customHeader;
  final double bottomPadding;
  final bool initiallyExpanded;
  final bool allowRefund;
  final bool allowQrCodePayment;
  final bool disableExpandable;
  final String? Function(AccountingDocumentDetailMobileDTO)? counterPartyTextBuilder;

  const AccountingDocumentCard(
    this.document, {
    super.key,
    this.customHeader,
    this.bottomPadding = 16.0,
    this.initiallyExpanded = false,
    this.allowRefund = false,
    this.allowQrCodePayment = false,
    this.disableExpandable = false,
    this.counterPartyTextBuilder,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PaymentExpandableCardState();
}

class _PaymentExpandableCardState extends ConsumerState<AccountingDocumentCard> {
  AppLocalizations get locale => AppLocalizations.of(context)!;

  AccountingDocumentMobileDTO get document => widget.document;

  bool get showQrCode =>
      (document.paymentAvailable ?? false) &&
      widget.allowQrCodePayment &&
      !document.isPaid &&
      !document.isOverpaid;

  late final ExpandableController _expandableController = ExpandableController()
    ..expanded = widget.initiallyExpanded;

  Future<void> _onTapPayViaQRCode() async {
    final String? qrPaymentPNGBase64 =
        (await ref.read(paymentsDetailProvider(widget.document.id!).future))?.qrPaymentPNGBase64;

    if (qrPaymentPNGBase64 == null) return;
    if (!mounted) return;

    showCustomBottomSheet(
      context,
      PaymentQrCodeBottomSheet(widget.document, qrPaymentPNGBase64: qrPaymentPNGBase64),
    );
  }

  void onTapRefund() {
    if (!widget.allowRefund) return;

    showCustomBottomSheet(context, CreateRefundBottomSheet(widget.document));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: CustomCard(
              padding: EdgeInsets.zero,
              child: ExpandablePanel(
                controller: _expandableController,
                theme: ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: !widget.disableExpandable,
                  tapBodyToExpand: !widget.disableExpandable,
                  tapHeaderToExpand: !widget.disableExpandable,
                  inkWellBorderRadius:
                      const BorderRadius.all(Radius.circular(AppTheme.cardBorderRadius)),
                ),
                header: ListenableBuilder(
                  listenable: _expandableController,
                  builder: (context, _) => AccountingDocumentCardHeader(
                    document: widget.document,
                    showExpandableIcon: !widget.disableExpandable,
                    isExpanded: _expandableController.expanded,
                    customHeader: widget.customHeader,
                  ),
                ),
                collapsed: _buildPayViaQrCodeButton(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                ),
                expanded: !_expandableController.expanded
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Builder(
                          builder: (context) {
                            final documentDetailProvider =
                                ref.watch(paymentsDetailProvider(widget.document.id!));

                            return documentDetailProvider.when(
                              loading: _buildLoading,
                              error: (_, __) => _buildError(),
                              data: (AccountingDocumentDetailMobileDTO? data) {
                                if (data == null) {
                                  return _buildError();
                                }

                                return ScrollOnExpand(
                                  child: Column(
                                    children: [
                                      _LabelValuePairText(
                                        locale.counterParty,
                                        widget.counterPartyTextBuilder?.call(data) ??
                                            data.supplier?.name,
                                      ),
                                      if (widget.document.formalPaymentDueDate != null) ...[
                                        _LabelValuePairText(
                                          locale.dueDate,
                                          widget.document.formalPaymentDueDate!.formatYMD(context),
                                        ),
                                      ],
                                      _LabelValuePairText(
                                        locale.methodOfPayment,
                                        data.paymentType?.translate(locale),
                                      ),
                                      _LabelValuePairText(
                                        locale.specificSymbol,
                                        data.bankPaymentSS,
                                      ),
                                      _LabelValuePairText(
                                        locale.variableSymbol,
                                        data.bankPaymentVS,
                                      ),
                                      _buildCounterPartyAccountNumberText(data),
                                      if (data.items.isNotEmpty) ...[
                                        SizedBox(height: 12.h),
                                        AccountingDocumentCardItems(data.items),
                                      ],
                                      if (data.attachments.isNotEmpty) ...[
                                        SizedBox(height: 12.h),
                                        Column(
                                          children: data.attachments
                                              .map(
                                                (attachmentData) =>
                                                    AccountingDocumentCardAttachment(
                                                  attachmentData,
                                                  key: Key(attachmentData.attachmentId),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                      _buildRefundButton(),
                                      _buildPayViaQrCodeButton(padding: EdgeInsets.only(top: 6.h)),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 60.0,
      child: Center(child: CustomLoadingIndicator()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        locale.failedToLoadDocumentDetails,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildCounterPartyAccountNumberText(AccountingDocumentDetailMobileDTO data) {
    final AccountingDocumentSubjectDTO? supplier = data.supplier;
    late final String text;

    if (supplier == null) {
      text = '';
    } else {
      text = switch (supplier.paymentDataType) {
        AccountingDocumentSubjectDTOPaymentDataTypeEnum.BANK_ACCOUNT =>
          '${supplier.bankAccountNumber}/${supplier.bankCode}',
        AccountingDocumentSubjectDTOPaymentDataTypeEnum.IBAN => supplier.bankIban ?? '',
        _ => '',
      };
    }

    return _LabelValuePairText(
      locale.counterPartyAccountNumber,
      text,
      zeroBottomPadding: true,
    );
  }

  Widget _buildRefundButton() {
    if (!widget.allowRefund) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButtonLight(
              onPressed: onTapRefund,
              text: locale.refund,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayViaQrCodeButton({required EdgeInsets padding}) {
    if (!showQrCode) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onTapPayViaQRCode,
              icon: Assets.icons.qrCode.svg(),
              label: Text(locale.payViaQRCode),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelValuePairText extends StatelessWidget {
  final String field;
  final String? value;
  final bool zeroBottomPadding;

  const _LabelValuePairText(
    this.field,
    this.value, {
    this.zeroBottomPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: zeroBottomPadding ? EdgeInsets.zero : EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              field,
              style: TextStyle(
                color: const Color(0xff475467),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value!,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xff101828),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
