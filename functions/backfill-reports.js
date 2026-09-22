'use strict';
// Run only with trusted Application Default Credentials (or demo emulators).
const projectId=process.argv[2];
if(!projectId) throw new Error('Usage: node functions/backfill-reports.js PROJECT_ID');
process.env.GCLOUD_PROJECT=projectId;
const backend=require('./index');
const {getFirestore,FieldPath}=require('firebase-admin/firestore');
(async()=>{
  const db=getFirestore();
  let last;
  let count=0;
  while(true){
    let query=db.collection('buyers').orderBy(FieldPath.documentId()).limit(200);
    if(last) query=query.startAfter(last);
    const page=await query.get();
    if(page.empty) break;
    for(const doc of page.docs){
      await backend.reconcilePurchase.run({params:{buyerId:doc.id}});
      count++;
    }
    last=page.docs[page.docs.length-1];
  }
  console.log('Reconciled '+count+' purchases into financial_reports/summary.');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
