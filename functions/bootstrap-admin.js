'use strict';
const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

async function main() {
  const [projectId, email, name, phone, branch] = process.argv.slice(2);
  const password = process.env.STOCKFLOW_ADMIN_PASSWORD;
  if (!projectId || !email || !name || !phone || !branch || !password || password.length < 8) {
    throw new Error('Usage: node bootstrap-admin.js PROJECT_ID EMAIL NAME PHONE BRANCH; set STOCKFLOW_ADMIN_PASSWORD to at least 8 characters.');
  }
  initializeApp({credential:applicationDefault(),projectId});
  const db=getFirestore();
  if (!(await db.collection('users').where('role','==','admin').limit(1).get()).empty) {
    throw new Error('An administrator already exists. Use in-app registration.');
  }
  const user=await getAuth().createUser({email,password,displayName:name});
  try {
    await db.collection('users').doc(user.uid).create({uid:user.uid,name,email:user.email,phone,role:'admin',branch,isActive:true,
      createdAt:FieldValue.serverTimestamp(),lastLogin:null});
  } catch(error) { await getAuth().deleteUser(user.uid); throw error; }
  console.log(`Administrator created: ${user.uid}. Sign in through the app.`);
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
