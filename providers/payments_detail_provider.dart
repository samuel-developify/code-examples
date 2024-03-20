final paymentsDetailProvider =
    FutureProvider.family<AccountingDocumentDetailMobileDTO?, int>((ref, int id) async {
  final PaymentsRepository paymentsRepository = ref.watch(paymentsRepositoryProvider);

  final AccountingDocumentDetailMobileDTO? accountingDocumentDetail =
      await paymentsRepository.getAccountingDocumentDetailForMobileApp(id);

  return accountingDocumentDetail;
});
