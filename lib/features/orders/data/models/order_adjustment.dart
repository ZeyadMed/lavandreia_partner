/// تعديل أصناف الطلب لما اللي وصل المغسلة يختلف عن اللي العميل طلبه
library;

/// نفس enum OrderAdjustmentItemAction في الباك إند
enum OrderAdjustmentAction {
  /// وصل صنف غير اللي اتطلب
  replace(apiName: 'Replace'),

  /// وصلت قطعة زيادة مكانتش في الطلب
  add(apiName: 'Add'),

  /// صنف اتطلب ومجاش
  remove(apiName: 'Remove');

  final String apiName;

  const OrderAdjustmentAction({required this.apiName});
}

/// سطر واحد في ريكوست التعديل
class OrderAdjustmentEntry {
  final OrderAdjustmentAction action;

  /// القطعة اللي في الطلب، null في الإضافة
  final int? orderItemId;

  /// الـ serviceItemId بتاع الصنف الجديد من أصناف المغسلة، null في الشيل
  final int? newServiceItemId;

  /// الكمية بعد التعديل، وفي الشيل بتبقى صفر
  final int newQuantity;

  const OrderAdjustmentEntry({
    required this.action,
    this.orderItemId,
    this.newServiceItemId,
    this.newQuantity = 0,
  });

  Map<String, dynamic> toJson() => {
    'orderItemId': orderItemId,
    'action': action.apiName,
    'newServiceItemId': newServiceItemId,
    'newQuantity': newQuantity,
  };
}
