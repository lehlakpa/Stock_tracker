'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {beforeUserCreated, beforeUserSignedIn} = require('firebase-functions/v2/identity');
const {onDocumentCreated, onDocumentUpdated, onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
initializeApp();
const db = getFirestore();

// Identity Platform is required. No client secret or public signup endpoint is used.
exports.requireAdminInvitation = beforeUserCreated(async (event) => {
  const email = event.data.email?.trim().toLowerCase();
  if (!email || email.includes('/')) throw new HttpsError('permission-denied', 'Administrator provisioning is required.');
  const ref = db.collection('account_requests').doc(email);
  await db.runTransaction(async tx => {
    const request = await tx.get(ref);
    const invitation = request.data();
    if (!invitation || invitation.consumed || invitation.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError('permission-denied', 'An unexpired administrator invitation is required.');
    }
    const admin = await tx.get(db.collection('users').doc(invitation.requestedByUid));
    if (admin.data()?.role !== 'admin' || admin.data()?.isActive !== true) {
      throw new HttpsError('permission-denied', 'The provisioning administrator is inactive.');
    }
    tx.update(ref, {consumed:true, consumedAt:FieldValue.serverTimestamp()});
  });
});

exports.checkAccountOnSignIn = beforeUserSignedIn(async event => {
  const ref = db.collection('users').doc(event.data.uid);
  const profile = await ref.get();
  // Provisioning may briefly precede the profile write.
  // Missing profiles receive no application access through Firestore rules.
  if (!profile.exists) return;
  if (profile.data().isActive !== true) throw new HttpsError('permission-denied', 'Your staff account is disabled. Contact your administrator.');
  await ref.update({lastLogin:Timestamp.now()});
});

// Read the current purchase inside the transaction, so late/repeated events
// and admin edits/deletions cannot double-count or leave stale totals.
async function syncPurchase(buyerId) {
  const ledger=db.doc('financial_reports/summary/processed/' + buyerId);
  const purchase=db.doc('buyers/' + buyerId);
  const report=db.doc('financial_reports/summary');
  await db.runTransaction(async tx => {
    const [oldDoc, currentDoc]=await Promise.all([tx.get(ledger),tx.get(purchase)]);
    const old=oldDoc.data() || {quantity:0,totalAmount:0,count:0};
    const current=currentDoc.data();
    const next=current ? {quantity:current.quantity,totalAmount:current.totalAmount,count:1} : {quantity:0,totalAmount:0,count:0};
    if(old.quantity===next.quantity && old.totalAmount===next.totalAmount && old.count===next.count) return;
    tx.set(report,{totalSales:FieldValue.increment(next.quantity-(old.quantity ?? 0)),
      totalIncome:FieldValue.increment(next.totalAmount-(old.totalAmount ?? 0)),purchaseCount:FieldValue.increment(next.count-(old.count ?? 0)),
      updatedAt:FieldValue.serverTimestamp()},{merge:true});
    tx.set(ledger,{...next,updatedAt:FieldValue.serverTimestamp()});
  });
}
exports.aggregatePurchase = onDocumentCreated({document:'buyers/{buyerId}',retry:true},event => syncPurchase(event.params.buyerId));
exports.reconcilePurchase = onDocumentWritten({document:'buyers/{buyerId}',retry:true},event => syncPurchase(event.params.buyerId));

// Admin SDK provisioning keeps the administrator's client session intact.
exports.createAccount = onCall(async request => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in as an administrator.');
  const admin = (await db.doc('users/' + request.auth.uid).get()).data();
  if (admin?.role !== 'admin' || admin.isActive !== true) throw new HttpsError('permission-denied', 'An active administrator is required.');
  const data = request.data || {};
  for (const key of ['name', 'email', 'password', 'phone', 'branch', 'role']) {
    if (typeof data[key] !== 'string') throw new HttpsError('invalid-argument', 'Invalid account details.');
  }
  if (!data.name.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email) || data.password.length < 8 || !['admin', 'staff'].includes(data.role)) {
    throw new HttpsError('invalid-argument', 'Enter a name, valid email, role and password of at least 8 characters.');
  }
  const {getAuth} = require('firebase-admin/auth');
  let account;
  try {
    account = await getAuth().createUser({email:data.email.trim().toLowerCase(), password:data.password, displayName:data.name.trim()});
    await db.doc('users/' + account.uid).create({uid:account.uid, name:data.name.trim(), email:account.email,
      phone:data.phone.trim(), branch:data.branch.trim(), role:data.role, isActive:true, createdAt:FieldValue.serverTimestamp(), lastLogin:null});
    return {uid:account.uid};
  } catch (error) {
    if (account) {
      try { await getAuth().deleteUser(account.uid); }
      catch (_) { throw new HttpsError('internal', 'Profile creation failed. The project owner must remove the orphaned Auth account before retrying.'); }
    }
    if (error.code === 'auth/email-already-exists') throw new HttpsError('already-exists', 'This email already has an account.');
    throw new HttpsError('internal', 'Account creation failed. Check the backend configuration before retrying.');
  }
});

// Staff cannot create notifications under the supplied rules. Deliver them here.
exports.notifyLowStock = onDocumentUpdated({document:'products/{productId}', retry:true}, async event => {
  if (!event.data) return;
  const before=event.data.before.data(), after=event.data.after.data();
  const limit=after.lowStockLimit ?? 5;
  if (after.remainingQuantity > limit || before.remainingQuantity <= limit) return;
  if (!after.lastUpdatedByUid) return;
  const ref=db.collection('notifications').doc(event.id);
  try {
    await ref.create({id:ref.id, title:'Low stock', message:after.name + ' has ' + after.remainingQuantity + ' units remaining.',
      recipientUid:after.lastUpdatedByUid, isRead:false, createdAt:FieldValue.serverTimestamp()});
  } catch(error) { if(error.code !== 6 && error.code !== 'already-exists') throw error; }
});
