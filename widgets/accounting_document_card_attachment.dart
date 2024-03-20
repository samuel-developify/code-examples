class AccountingDocumentCardAttachment extends ConsumerStatefulWidget {
  final AccountingDocumentAttachmentMobileDTO attachment;

  const AccountingDocumentCardAttachment(this.attachment, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PaymentAttachmentCardState();
}

class _PaymentAttachmentCardState extends ConsumerState<AccountingDocumentCardAttachment> {
  AppLocalizations get locale => AppLocalizations.of(context)!;

  AccountingDocumentAttachmentMobileDTO get attachment => widget.attachment;

  late bool isPreviewingAttachment = false, isDownloadingAttachment = false;

  void onTapAttachment(BuildContext context) {
    if (attachment.isPdf || attachment.isJpg || attachment.isPng) {
      isPreviewingAttachment = true;

      final Widget screen = attachment.isPdf
          ? AttachmentPreviewScreen<PaymentsAttachmentNotifier>.pdf(
              asyncValue: paymentsAttachmentProvider(widget.attachment.downloadArgs),
              attachmentName: widget.attachment.downloadArgs.fileName,
              downloadAttachmentData: ref
                  .read(paymentsAttachmentProvider(widget.attachment.downloadArgs).notifier)
                  .download,
            )
          : AttachmentPreviewScreen<PaymentsAttachmentNotifier>.image(
              asyncValue: paymentsAttachmentProvider(widget.attachment.downloadArgs),
              attachmentName: widget.attachment.downloadArgs.fileName,
              downloadAttachmentData: ref
                  .read(paymentsAttachmentProvider(widget.attachment.downloadArgs).notifier)
                  .download,
            );

      Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
          .then((_) => isPreviewingAttachment = false);
    } else {
      showAttachmentActionsDialog(
        context,
        isAttachmentPreviewable: false,
        onPreview: null,
        onDownload: () {
          downloadAttachment();
          context.pop();
        },
        onCancel: context.pop,
      );
    }
  }

  Future<void> downloadAttachment() async {
    ref.read(paymentsAttachmentProvider(widget.attachment.downloadArgs).notifier).download();
  }

  void onSaveAttachment(Uint8List bytes) async {
    await shareFile(context, bytes: bytes, fileName: attachment.fileName);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      paymentsAttachmentProvider(widget.attachment.downloadArgs),
      (_, newState) {
        if (newState == null) return;

        newState.when(
          loading: () => setState(() => isDownloadingAttachment = true),
          error: (_, __) {
            setState(() => isDownloadingAttachment = false);
            showErrorDialog(context, locale.failedToDownloadAttachment);
          },
          data: (Uint8List? bytes) {
            setState(() => isDownloadingAttachment = false);

            if (isPreviewingAttachment) return;

            if (bytes == null) {
              showErrorDialog(context, locale.failedToDownloadAttachment);
            } else {
              onSaveAttachment(bytes);
            }
          },
        );
      },
    );

    return AttachmentCard(
      fileName: attachment.fileName,
      contentType: attachment.contentType,
      fileSize: attachment.size,
      showLoadingIndicator: isDownloadingAttachment,
      onTap: () => onTapAttachment(context),
    );
  }
}
