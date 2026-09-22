'use strict';
// Live, reversible smoke test. Only this run's uniquely named accounts are deleted.
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');
const backendRequire = require('node:module').createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp,deleteApp} = backendRequire('firebase/app');
const {getAuth,signInWithEmailAndPassword,createUserWithEmailAndPassword} = backendRequire('firebase/auth');
const {getFirestore,doc,setDoc,getDoc,serverTimestamp,terminate} = backendRequire('firebase/firestore');
const cliAuth = require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
const assert = require('node:assert/strict');

async function main() {
  const email=process.env.STOCKFLOW_ADMIN_EMAIL, password=process.env.STOCKFLOW_ADMIN_PASSWORD;
  if (!email || !password) throw new Error('Set administrator credentials in environment variables.');
  const source=fs.readFileSync(path.join(__dirname,'../lib/firebase_options.dart'),'utf8');
  const apiKey=source.match(/static const FirebaseOptions web[\s\S]*?apiKey: '([^']+)'/)[1];
  const projectId='stocktracker-f8f91';
  const options={apiKey,projectId,appId:'1:690501444152:web:eff4774e8f1385fedabccd'};
  const operator=cliAuth.getProjectDefaultAccount(process.cwd());
  const token=await cliAuth.getAccessToken(operator.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  const {initializeApp:initializeAdmin}=backendRequire('firebase-admin/app');
  const {getAuth:adminAuth}=backendRequire('firebase-admin/auth');
  initializeAdmin({projectId,credential:{getAccessToken:async()=>({access_token:token.access_token,expires_in:3600})}});
  const app=initializeApp(options,'registration-check-admin');
  const auth=getAuth(app), db=getFirestore(app);
  const created=[], secondaryApps=[], databases=[];
  try {
    await signInWithEmailAndPassword(auth,email,password);
    const adminUid=auth.currentUser.uid;
    assert.equal((await getDoc(doc(db,'users',adminUid))).data().role,'admin');
    for(const role of ['staff','admin']) {
      const secondary=initializeApp(options,'registration-check-secondary-'+role);
      secondaryApps.push(secondary);
      const secondaryAuth=getAuth(secondary);
      const testEmail='stockflow-check-'+role+'-'+crypto.randomUUID()+'@example.com';
      const testPassword=crypto.randomBytes(24).toString('base64url');
      const account=await createUserWithEmailAndPassword(secondaryAuth,testEmail,testPassword);
      created.push(account.user.uid);
      await setDoc(doc(db,'users',account.user.uid),{uid:account.user.uid,name:'Registration smoke test',email:testEmail,
        phone:'',branch:'',role,isActive:true,createdAt:serverTimestamp(),lastLogin:null});
      const secondaryDb=getFirestore(secondary);
      databases.push(secondaryDb);
      const profile=(await getDoc(doc(secondaryDb,'users',account.user.uid))).data();
      assert.equal(profile.role,role);
      assert.equal(profile.isActive,true);
      assert.equal(auth.currentUser.uid,adminUid);
      await assert.rejects(()=>createUserWithEmailAndPassword(secondaryAuth,testEmail,testPassword),{code:'auth/email-already-in-use'});
      console.log(JSON.stringify({role,registration:'passed',profileRead:'passed',adminSession:'preserved',duplicateEmail:'rejected'}));
    }
  } finally {
    let cleanupFailed=false;
    for(const uid of created) {
      const url=`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;
      try {
        const response=await fetch(url,{method:'DELETE',headers:{Authorization:'Bearer '+token.access_token}});
        if(!response.ok && response.status!==404) throw new Error('Profile cleanup failed: '+response.status);
        await adminAuth().deleteUser(uid);
      } catch(error) {cleanupFailed=true;console.error('Cleanup required for test UID '+uid+': '+error.message);}
    }
    await Promise.all([terminate(db),...databases.map(d=>terminate(d))]);
    await Promise.all([deleteApp(app),...secondaryApps.map(a=>deleteApp(a))]);
    if(cleanupFailed) throw new Error('Test cleanup needs attention.');
    console.log(JSON.stringify({temporaryAccountsRemoved:created.length}));
  }
}
main().catch(error=>{console.error(error.code || error.message);process.exitCode=1;});
