class PaymentsRepository {
  final HttpService _httpService;

  PaymentsRepository(this._httpService);

  Future<AccountingDocumentDetailMobileDTO?> getAccountingDocumentDetailForMobileApp(int id) async {
    try {
      logger.d('PaymentsRepository: getAccountingDocumentDetailForMobileApp');

      final result = await _httpService.get('${AppConfig.apiUrl}.../');

      return AccountingDocumentDetailMobileDTO.fromJson(result);
    } catch (e, st) {
      logger.e(
        'PaymentsRepository: getAccountingDocumentDetailForMobileApp error',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
