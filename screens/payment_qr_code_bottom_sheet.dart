class PaymentQrCodeBottomSheet extends StatefulWidget {
  final AccountingDocumentMobileDTO document;
  final String qrPaymentPNGBase64;

  const PaymentQrCodeBottomSheet(
    this.document, {
    super.key,
    required this.qrPaymentPNGBase64,
  });

  @override
  State<PaymentQrCodeBottomSheet> createState() => _PaymentQrCodeBottomSheetState();
}

class _PaymentQrCodeBottomSheetState extends State<PaymentQrCodeBottomSheet> {
  AppLocalizations get locale => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      pinnedHeader: PaymentsBottomSheetHeader(title: locale.payment),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          PaymentQrCodeShareImage(
            fileName: widget.document.title,
            qrPaymentPNGBase64: widget.qrPaymentPNGBase64,
          ),
          SizedBox(height: 16.h),
          _buildQrCodeInfoText(),
          SizedBox(height: 42.h),
        ],
      ),
    );
  }

  Widget _buildQrCodeInfoText() {
    return Text(
      locale.afterSavingQRCodeYouCanLoadItIntoBankApp,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xff475467),
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
