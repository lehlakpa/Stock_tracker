const fs=require('fs');
const write=(p,s)=>fs.writeFileSync(p,s);
const specs={
auth:{imports:['user_model','account_input'],events:[
 ['AuthStarted',''],['AuthenticatedUserChanged','String? uid'],['UserStatusChanged','UserModel? user,String uid'],
 ['LoginRequested','String email,String password','write'],['PasswordResetRequested','String email','write'],['LogoutRequested','','write'],
 ['CreateStaffRequested','AccountInput input','write'],['CreateAdminRequested','AccountInput input','write']]},
stock:{imports:['purchase_input'],events:[['StockSubscriptionRequested',''],['StockSearchChanged','String query'],['StockCategoryChanged','String category,bool lowOnly'],
 ['StockAddRequested','Map<String,dynamic> fields,int quantity','write'],['StockUpdateRequested','String productId,int delta,String note,Map<String,dynamic>? details','write'],['StockSaleRequested','PurchaseInput purchase','write']]},
buyer:{imports:['purchase_input'],events:[['BuyersSubscriptionRequested',''],['BuyerSearchChanged','String query'],['BuyerDetailsRequested','String id'],['BuyerAddRequested','PurchaseInput purchase','write']]},
staff:{imports:['account_input','user_model'],events:[['StaffSubscriptionRequested',''],['StaffCreateRequested','AccountInput input','write'],['AdminCreateRequested','AccountInput input','write'],['StaffActivationChanged','UserModel user,bool active','write'],['StaffUpdateRequested','String uid,String name,String phone,String branch','write']]},
notification:{imports:[],events:[['NotificationsSubscriptionRequested',''],['NotificationReadRequested','String id','write'],['AllNotificationsReadRequested','','write']]},
dashboard:{imports:[],events:[['DashboardSubscriptionRequested',''],['DashboardRefreshRequested','','write']]}
};
for(const [feature,spec] of Object.entries(specs)){
const cap=feature[0].toUpperCase()+feature.slice(1);
let s=`import 'package:equatable/equatable.dart';\n${spec.imports.map(x=>`import '../../models/${x}.dart';`).join('\n')}
abstract class ${cap}Event extends Equatable {const ${cap}Event(); @override List<Object?> get props=>[];}
abstract class ${cap}Mutation extends ${cap}Event {final String operationId; const ${cap}Mutation({required this.operationId}); @override List<Object?> get props=>[operationId];}
`;
for(const [name,fields,mutation] of spec.events){
 const parsed=fields?fields.replaceAll('Map<String,dynamic>','MAP').split(',').map(x=>x.replaceAll('MAP','Map<String,dynamic>').trim().split(' ')):[];
 s+=`class ${name} extends ${cap}${mutation?'Mutation':'Event'} { ${parsed.map(([t,n])=>`final ${t} ${n};`).join(' ')}
 const ${name}(${parsed.map(([t,n])=>`this.${n}`).join(',')}${mutation?`${parsed.length?',':''}{required super.operationId}`:''});
 @override List<Object?> get props=>[${mutation?'...super.props,':''}${parsed.map(x=>x[1]).join(',')}];}\n`;
}
write(`lib/blocs/${feature}/${feature}_event.dart`,s);
}
