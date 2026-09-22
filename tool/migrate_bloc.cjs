const fs = require('fs');
const path = require('path');
const write=(p,s)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s);};
const move=(from,to,changes)=>{let s=fs.readFileSync(from,'utf8');for(const [a,b] of changes)s=s.replaceAll(a,b);write(to,s);fs.unlinkSync(from);};
move('lib/services/auth_service.dart','lib/repositories/auth_repository.dart', [['AuthService','AuthRepository'],["'app_error.dart'","'../services/app_error.dart'"]]);
move('lib/services/firestore_service.dart','lib/repositories/stock_repository.dart', [['FirestoreService','StockRepository'],["'app_error.dart'","'../services/app_error.dart'"]]);
move('lib/services/notification_service.dart','lib/repositories/notification_repository.dart', [['NotificationService','NotificationRepository']]);
for(const p of ['auth_provider','stock_provider','buyer_provider'])fs.unlinkSync('lib/providers/'+p+'.dart');

const commonFields=[['int','effect','0'],['String?','operationId','null'],['String?','error','null']];
const features={
 auth:{imports:["../../models/user_model.dart"],fields:[['UserModel?','user','null'],['String?','uid','null'],['AuthAccess','access','AuthAccess.checking']],extra:'enum AuthAccess { checking, signedOut, active, inactive, missing, invalid }'},
 stock:{imports:["../../models/stock_model.dart"],fields:[['List<StockModel>','products','const []'],['List<StockUpdate>','history','const []'],['String','query',"''"],['String','category',"'All'"],['bool','lowOnly','false']],getters:`List<StockModel> get filtered => products.where((p)=>(p.name.toLowerCase().contains(query.toLowerCase()) || p.sku.toLowerCase().contains(query.toLowerCase())) && (category=='All' || p.category==category) && (!lowOnly || p.isLow)).toList();`},
 buyer:{imports:["../../models/buyer_model.dart"],fields:[['List<BuyerModel>','buyers','const []'],['String','query',"''"],['String?','selectedId','null']],getters:`List<BuyerModel> get filtered => buyers.where((b)=>b.name.toLowerCase().contains(query.toLowerCase()) || b.phone.contains(query)).toList(); BuyerModel? get selected => buyers.where((b)=>b.id==selectedId).firstOrNull;`},
 staff:{imports:["../../models/user_model.dart"],fields:[['List<UserModel>','users','const []']]},
 notification:{imports:["../../models/notification_model.dart"],fields:[['List<NotificationModel>','notifications','const []']]},
 dashboard:{imports:[],fields:[['int','totalStock','0'],['int','remainingStock','0'],['int','lowStockCount','0'],['int','electronicsQuantity','0'],['int','kitchenQuantity','0'],['int?','totalSales','null'],['double?','totalIncome','null'],['int?','totalStaff','null']]},
};
for(const [name, spec] of Object.entries(features)){
 const cap=name[0].toUpperCase()+name.slice(1), fields=[...spec.fields,...commonFields];
 const arguments=fields.map(([t,n,d])=>`this.${n}=${d}`).join(',');
 const params=fields.map(([t,n])=>`${t.endsWith('?')?t:t+'?'} ${n}`).join(',');
 const values=fields.map(([t,n])=>`${n}: ${n} ?? this.${n}`).join(',');
 const types=['Initial','Loading','Loaded','Submitting','Success','Failure'];
 write(`lib/blocs/${name}/${name}_state.dart`, `import 'package:equatable/equatable.dart';\n${spec.imports.map(p=>`import '${p}';`).join('\n')}
enum ${cap}Status { initial, loading, loaded, submitting, success, failure }
${spec.extra||''}
class ${cap}State extends Equatable {
 final ${cap}Status status;
 ${fields.map(([t,n])=>`final ${t} ${n};`).join('\n')}
 const ${cap}State({this.status=${cap}Status.initial,${arguments}});
 bool get submitting => status==${cap}Status.submitting;
 bool get loading => status==${cap}Status.initial || status==${cap}Status.loading;
 ${spec.getters||''}
 ${cap}State copyWith({${cap}Status? status,${params},bool clearError=false${name==='auth'?', bool clearSession=false':''}}) {
 final next=${cap}State(status:status ?? this.status,${values});
 return switch(next.status) {${types.map(t=>`${cap}Status.${t.toLowerCase()} => ${cap}${t}.from(next, clearError:clearError${name==='auth'?',clearSession:clearSession':''})`).join(',')}};
 }
 @override List<Object?> get props => [status,${fields.map(f=>f[1]).join(',')}];
}
${types.map(t=>`class ${cap}${t} extends ${cap}State {
 const ${cap}${t}():super(status:${cap}Status.${t.toLowerCase()});
 ${cap}${t}.from(${cap}State s,{bool clearError=false${name==='auth'?',bool clearSession=false':''}}):super(status:${cap}Status.${t.toLowerCase()},${fields.map(([ty,n])=>`${n}:${n==='error'?'clearError ? null : s.error':name==='auth'&&['user','uid'].includes(n)?`clearSession ? null : s.${n}`:`s.${n}`}`).join(',')});
}`).join('\n')}
`);
}
write('lib/models/operation_id.dart',`import 'dart:math';
String newOperationId() => '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1<<32)}-${Random.secure().nextInt(1<<32)}';
`);
