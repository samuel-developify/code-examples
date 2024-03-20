class CreateRefundNotifier extends StateNotifier<AsyncValue<void>?> {
  final RefundRepository _refundRepository;
  final int _accountId;

  CreateRefundNotifier(this._refundRepository, {required int accountId})
      : _accountId = accountId,
        super(null);

  Future<void> create({
    required String description,
    required String subject,
    required int? documentId,
  }) async {
    if (documentId == null) throw Exception();

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final HomeAccountOptionsDTO? options = await _refundRepository.getOptions();
      if (options == null) throw Exception();

      final int? categoryId =
          options.categories.firstWhereOrNull((category) => category.code == 'COMPLAINT')?.id;
      final int? areaId = options.areas.firstWhereOrNull((area) => area.code == 'PAYMENTS')?.id;
      if (categoryId == null || areaId == null) throw Exception();

      final TicketSaveMobileDTOInternal newTicket = TicketSaveMobileDTOInternal(
        subject: subject,
        description: description,
        relatedEntities: [
          TicketRelatedDTOInternal(
            entityId: '$_accountId',
            entityType: TicketRelatedDTOInternalEntityTypeEnum.HOME_ACCOUNT,
          ),
          TicketRelatedDTOInternal(
            entityId: '$documentId',
            entityType: TicketRelatedDTOInternalEntityTypeEnum.ACCOUNTING_DOCUMENT,
          ),
        ],
        categoryId: categoryId,
        areaId: areaId,
      );

      final bool isOK = await _refundRepository.createTicket(newTicket);

      if (!isOK) throw Exception();
    });
  }
}

final createRefundProvider = StateNotifierProvider<CreateRefundNotifier, AsyncValue<void>?>((ref) {
  final RefundRepository refundRepository = ref.watch(refundRepositoryProvider);

  final JwtPayload? jwtPayload = ref.watch(accessTokenPayloadProvider);

  return CreateRefundNotifier(refundRepository, accountId: jwtPayload!.homeAccount!.id!);
});
