'use strict';
// Uses the operator's existing Firebase CLI login. Never stores passwords.
const path = require('node:path');
const backendRequire = require('node:module').createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp} = backendRequire('firebase-admin/app');
const {getAuth} = backendRequire('firebase-admin/auth');
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));

async function main() {
  const account = cliAuth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Sign in with firebase login first.');
  const projectId = 'stocktracker-f8f91';
  const email = process.env.STOCKFLOW_ADMIN_EMAIL;
  if (!email) throw new Error('Set STOCKFLOW_ADMIN_EMAIL to the requested account email.');
  const credential = {getAccessToken: async () => {
    const token = await cliAuth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
    return {access_token: token.access_token, expires_in: token.expires_in || 3600};
  }};
  initializeApp({projectId, credential});
  const auth = getAuth();
  const documentsUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
  async function firestore(suffix, options = {}) {
    const token = await credential.getAccessToken();
    const response = await fetch(documentsUrl + suffix, {...options, headers:{Authorization:'Bearer ' + token.access_token,'Content-Type':'application/json'}});
    const result = await response.json();
    if (!response.ok) throw new Error('Firestore: ' + (result.error?.message || response.status));
    return result;
  }
  let existing;
  try { existing = await auth.getUserByEmail(email); }
  catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
  // Verify Firestore authorization before creating an Auth record.
  await firestore('/users?pageSize=1');
  if (process.argv.includes('--check')) {
    console.log(JSON.stringify({projectId, authorized:true, accountExists:!!existing}));
    return;
  }
  if (existing) throw new Error('This email already exists; no account or password was changed.');
  const password = process.env.STOCKFLOW_ADMIN_PASSWORD;
  if (!password || password.length < 8) throw new Error('A password of at least 8 characters is required.');
  const user = await auth.createUser({email,password,displayName:'Admin Test'});
  try {
    const strings = {uid:user.uid,name:'Admin Test',email,phone:'',branch:'',role:'admin'};
    await firestore('/users?documentId=' + encodeURIComponent(user.uid), {method:'POST',body:JSON.stringify({fields:{
      ...Object.fromEntries(Object.entries(strings).map(([key,value])=>[key,{stringValue:value}])),
      isActive:{booleanValue:true},createdAt:{timestampValue:new Date().toISOString()},lastLogin:{nullValue:null},
    }})});
  } catch(error) {
    try {await auth.deleteUser(user.uid);} catch (_) {
      throw new Error('Profile creation failed and Auth cleanup failed; operator recovery required.');
    }
    throw error;
  }
  const profile = (await firestore('/users/' + encodeURIComponent(user.uid))).fields;
  const verified = await auth.getUser(user.uid);
  console.log(JSON.stringify({email:verified.email,role:profile.role.stringValue,isActive:profile.isActive.booleanValue,created:true}));
}
main().catch(error => {console.error(error.code || error.message);process.exitCode=1;});
