final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);

  return PaymentsRepository(httpService);
});
