enum PaymentStatus {
  paid('Paid'),
  credit('Credit');

  const PaymentStatus(this.label);
  final String label;

  static PaymentStatus fromValue(Object? value) =>
      value == 'credit' ? PaymentStatus.credit : PaymentStatus.paid;
}
