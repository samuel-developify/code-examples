class CreateRefundBottomSheet extends ConsumerStatefulWidget {
  final AccountingDocumentMobileDTO document;

  const CreateRefundBottomSheet(this.document, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateRefundBottomSheetState();
}

class _CreateRefundBottomSheetState extends ConsumerState<CreateRefundBottomSheet> {
  AppLocalizations get locale => AppLocalizations.of(context)!;

  late final FormGroup formGroup = FormGroup({
    'description': FormControl<String>(validators: [Validators.required]),
  });

  void onTapSave() {
    formGroup.markAllAsTouched();
    if (!formGroup.valid) return;

    ref.read(createRefundProvider.notifier).create(
          description: formGroup.control('description').value,
          subject: '${locale.documentRefund} ${widget.document.title}',
          documentId: widget.document.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      createRefundProvider,
      (_, newState) => newState?.whenOrNull(
        error: (_, __) => showErrorDialog(context, locale.requestRefundFailure),
        data: (_) {
          showSnackbar(locale.requestRefundSuccess, duration: const Duration(seconds: 5));
          Navigator.of(context).pop();
        },
      ),
    );

    return LoadingOverlay(
      isLoading: ref.watch(createRefundProvider)?.isLoading ?? false,
      child: BottomSheetScaffold(
        child: ReactiveForm(
          formGroup: formGroup,
          child: Column(
            children: [
              const SizedBox(height: 12.0),
              BottomSheetHeader(title: locale.refund),
              SizedBox(height: 24.h),
              _buildDescriptionTextField(),
              SizedBox(height: 16.h),
              _buildSaveButton(),
              SizedBox(height: 6.h),
              _buildCancelButton(),
              SizedBox(height: 42.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionTextField() {
    return CustomReactiveTextField(
      title: locale.description,
      formControlName: 'description',
      minLines: 10,
      maxLines: 15,
    );
  }

  Widget _buildSaveButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onTapSave,
            child: Text(locale.save),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: context.pop,
            child: Text(locale.cancel),
          ),
        ),
      ],
    );
  }
}
