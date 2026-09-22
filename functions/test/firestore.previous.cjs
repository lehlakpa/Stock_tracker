'use strict';
const {before,after,beforeEach,test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails} = require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,getDocs,collection,query,where,orderBy,updateDoc,writeBatch,serverTimestamp,Timestamp,runTransaction} = require('firebase/firestore');
let env;
const projectId='demo-stockflow';
const profile=(uid,role='staff',isActive=true)=>({uid,name:uid,email:`${uid}@test.com`,phone:'123456',role,branch:'Main',isActive,createdAt:Timestamp.now(),lastLogin:null});
const product=()=>({id:'p1',name:'Laptop',sku:'L1',category:'Electronics',description:'Portable',imageUrl:'',purchasePrice:50,sellingPrice:100,
  addedQuantity:10,soldQuantity:0,remainingQuantity:10,lowStockLimit:2,addedDate:Timestamp.now(),lastUpdatedAt:Timestamp.now(),
  lastUpdatedByUid:'admin',lastUpdatedByName:'admin',lastUpdatedByEmail:'admin@test.com',lastUpdateId:'initial'});
const dbFor=uid=>env.authenticatedContext(uid,{email:`${uid}@test.com`}).firestore();
before(async()=>{
  const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8180').split(':');
  env=await initializeTestEnvironment({projectId,firestore:{rules:readFileSync('../firestore.rules','utf8'),host,port:Number(port)}});
});
after(async()=>{await env?.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await Promise.all(['admin','staff','other','inactive'].map(uid=>setDoc(doc(db,'users',uid),profile(uid,uid==='admin'?'admin':'staff',uid!=='inactive'))));
    await setDoc(doc(db,'products','p1'),product());
    await setDoc(doc(db,'reports','summary'),{totalSales:0,totalIncome:0});
  });
});
function actor(uid){return {lastUpdatedAt:serverTimestamp(),lastUpdatedByUid:uid,lastUpdatedByName:uid,lastUpdatedByEmail:`${uid}@test.com`};}
function log(uid,id,before,after,type='adjustment') {return {id,productId:'p1',productName:'Laptop',previousQuantity:before,
  changedQuantity:after-before,newQuantity:after,updateType:type,note:'Count verified',updatedByUid:uid,updatedByName:uid,updatedByEmail:`${uid}@test.com`,createdAt:serverTimestamp()};}
function adjustment(uid='staff',next=12,extra={}){
  const db=dbFor(uid),batch=writeBatch(db),id='adjust';
  batch.update(doc(db,'products','p1'),{remainingQuantity:next,addedQuantity:next,lastUpdateId:id,...actor(uid),...extra});
  batch.set(doc(db,'stock_updates',id),log(uid,id,10,next));
  return batch.commit();
}
function sale(uid='staff',quantity=3,price=100){
  const db=dbFor(uid),batch=writeBatch(db),id='purchase';
  batch.update(doc(db,'products','p1'),{remainingQuantity:10-quantity,soldQuantity:quantity,lastUpdateId:id,...actor(uid)});
  batch.set(doc(db,'stock_updates',id),log(uid,id,10,10-quantity,'sale'));
  batch.set(doc(db,'buyers',id),{id,name:'Customer',phone:'1234',address:'Town',productId:'p1',productName:'Laptop',quantity,unitPrice:price,totalAmount:quantity*price,
    purchaseDate:Timestamp.now(),warrantyStartDate:Timestamp.now(),warrantyEndDate:Timestamp.fromMillis(Date.now()+86400000),notes:'',recordedByUid:uid,recordedByName:uid,createdAt:serverTimestamp()});
  return batch.commit();
}
test('unauthenticated and inactive users cannot read inventory',async()=>{
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'products','p1')));
  await assertFails(getDoc(doc(dbFor('inactive'),'products','p1')));
  await assertSucceeds(getDoc(doc(dbFor('inactive'),'users','inactive')));
});
test('staff read inventory but cannot read reports or other profiles',async()=>{
  await assertSucceeds(getDoc(doc(dbFor('staff'),'products','p1')));
  await assertFails(getDoc(doc(dbFor('staff'),'reports','summary')));
  await assertFails(getDoc(doc(dbFor('staff'),'users','other')));
  await assertSucceeds(getDoc(doc(dbFor('admin'),'reports','summary')));
});
test('only admins create users and nobody changes their own role',async()=>{
  const data={...profile('new'),createdAt:serverTimestamp()};
  await assertFails(setDoc(doc(dbFor('staff'),'users','new'),data));
  await assertSucceeds(setDoc(doc(dbFor('admin'),'users','new'),data));
  await assertFails(updateDoc(doc(dbFor('staff'),'users','staff'),{role:'admin'}));
  await assertFails(updateDoc(doc(dbFor('admin'),'users','admin'),{role:'staff'}));
  await assertSucceeds(updateDoc(doc(dbFor('admin'),'users','staff'),{isActive:false}));
});
test('staff cannot forge provisioning requests',async()=>{
  const data={email:'new@test.com',requestedByUid:'staff',role:'admin',createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+60000)};
  await assertFails(setDoc(doc(dbFor('staff'),'account_requests','new@test.com'),data));
  await assertSucceeds(setDoc(doc(dbFor('admin'),'account_requests','new@test.com'),{...data,requestedByUid:'admin'}));
});
test('valid stock adjustment requires an atomic audit entry',async()=>{
  await assertFails(updateDoc(doc(dbFor('staff'),'products','p1'),{remainingQuantity:12,addedQuantity:12,lastUpdateId:'fake',...actor('staff')}));
  await assertSucceeds(adjustment());
});
test('negative stock, changed prices and spoofed actors are rejected',async()=>{
  await assertFails(adjustment('staff',-1));
  await assertFails(adjustment('staff',12,{sellingPrice:1}));
  await assertFails(adjustment('staff',12,{lastUpdatedByUid:'admin'}));
});
test('audit entries cannot exist without the matching stock write or be edited',async()=>{
  await assertFails(setDoc(doc(dbFor('staff'),'stock_updates','fake'),log('staff','fake',10,12)));
  await assertSucceeds(adjustment());
  await assertFails(updateDoc(doc(dbFor('admin'),'stock_updates','adjust'),{note:'Changed'}));
});
test('staff only query their own history; admins see all',async()=>{
  await assertSucceeds(adjustment());
  await assertFails(getDocs(collection(dbFor('staff'),'stock_updates')));
  await assertSucceeds(getDocs(query(collection(dbFor('staff'),'stock_updates'),where('updatedByUid','==','staff'),orderBy('createdAt','desc'))));
  await assertSucceeds(getDocs(collection(dbFor('admin'),'stock_updates')));
});
test('purchase creates buyer, sale history and stock reduction together',async()=>{
  await assertSucceeds(sale());
  await assertSucceeds(getDoc(doc(dbFor('other'),'buyers','purchase')));
  await assertFails(updateDoc(doc(dbFor('staff'),'buyers','purchase'),{totalAmount:1}));
  await assertFails(updateDoc(doc(dbFor('staff'),'reports','summary'),{totalIncome:300}));
});
test('overselling and price tampering are denied',async()=>{
  await assertFails(sale('staff',11));
  await assertFails(sale('staff',3,1));
});
test('notifications are private and only read state is mutable',async()=>{
  const db=dbFor('staff');
  await assertSucceeds(setDoc(doc(db,'notifications','n1'),{id:'n1',title:'Low stock',message:'2 remaining',recipientUid:'staff',isRead:false,createdAt:serverTimestamp()}));
  await assertFails(getDoc(doc(dbFor('other'),'notifications','n1')));
  await assertSucceeds(updateDoc(doc(db,'notifications','n1'),{isRead:true}));
  await assertFails(updateDoc(doc(db,'notifications','n1'),{recipientUid:'other'}));
});
test('admin adds products with initial audit entry; staff cannot',async()=>{
  async function add(uid){
    const db=dbFor(uid),batch=writeBatch(db);
    batch.set(doc(db,'products','p2'),{...product(),id:'p2',addedDate:serverTimestamp(),...actor(uid),lastUpdateId:'new'});
    batch.set(doc(db,'stock_updates','new'),{...log(uid,'new',0,10,'initial'),productId:'p2'});
    return batch.commit();
  }
  await assertFails(add('staff'));
  await assertSucceeds(add('admin'));
});
test('simultaneous purchases cannot oversell the same stock',async()=>{
  async function buy(id){
    const uid='staff',db=dbFor(uid);
    return runTransaction(db,async tx=>{
      const ref=doc(db,'products','p1'),p=(await tx.get(ref)).data(),qty=7;
      if(p.remainingQuantity<qty) throw new Error('Insufficient stock');
      tx.update(ref,{remainingQuantity:p.remainingQuantity-qty,soldQuantity:p.soldQuantity+qty,lastUpdateId:id,...actor(uid)});
      tx.set(doc(db,'stock_updates',id),log(uid,id,p.remainingQuantity,p.remainingQuantity-qty,'sale'));
      const now=Timestamp.now();
      tx.set(doc(db,'buyers',id),{id,name:'Customer',phone:'1234',address:'Town',productId:'p1',productName:p.name,quantity:qty,unitPrice:p.sellingPrice,totalAmount:qty*p.sellingPrice,
        purchaseDate:now,warrantyStartDate:now,warrantyEndDate:now,notes:'',recordedByUid:uid,recordedByName:uid,createdAt:serverTimestamp()});
    });
  }
  const results=await Promise.allSettled([buy('a'),buy('b')]);
  require('node:assert/strict').equal(results.filter(r=>r.status==='fulfilled').length,1);
  require('node:assert/strict').equal((await getDoc(doc(dbFor('staff'),'products','p1'))).data().remainingQuantity,3);
});

test('blocking hook rejects uninvited, expired, inactive-admin and reused requests',async()=>{
  const backend=require('../index');
  const {rejects}=require('node:assert/strict');
  await rejects(()=>backend.requireAdminInvitation.run({data:{email:'new@test.com'}}));
  const seed=async (requestedByUid,expiresAt)=>env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),'account_requests','new@test.com'),{
    email:'new@test.com',requestedByUid,role:'staff',createdAt:Timestamp.now(),expiresAt,
  }));
  await seed('admin',Timestamp.fromMillis(Date.now()-1000));
  await rejects(()=>backend.requireAdminInvitation.run({data:{email:'new@test.com'}}));
  await seed('inactive',Timestamp.fromMillis(Date.now()+60000));
  await rejects(()=>backend.requireAdminInvitation.run({data:{email:'new@test.com'}}));
  await seed('admin',Timestamp.fromMillis(Date.now()+60000));
  await backend.requireAdminInvitation.run({data:{email:'new@test.com'}});
  await rejects(()=>backend.requireAdminInvitation.run({data:{email:'new@test.com'}}));
});

test('sign-in hook rejects inactive profiles and records last login',async()=>{
  const backend=require('../index');
  const {rejects,ok}=require('node:assert/strict');
  await rejects(()=>backend.checkAccountOnSignIn.run({data:{uid:'inactive'}}));
  await backend.checkAccountOnSignIn.run({data:{uid:'staff'}});
  ok((await getDoc(doc(dbFor('staff'),'users','staff'))).data().lastLogin instanceof Timestamp);
  await backend.checkAccountOnSignIn.run({data:{uid:'new-user-without-profile'}});
});

test('repeated aggregate events count each purchase exactly once',async()=>{
  const backend=require('../index');
  const event={params:{buyerId:'event-buyer'},data:{data:()=>({quantity:3,totalAmount:300})}};
  await Promise.all([backend.aggregatePurchase.run(event),backend.aggregatePurchase.run(event)]);
  const report=(await getDoc(doc(dbFor('admin'),'reports','summary'))).data();
  require('node:assert/strict').equal(report.totalSales,3);
  require('node:assert/strict').equal(report.totalIncome,300);
});
