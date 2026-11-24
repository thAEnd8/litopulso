// Genera tests/golden.json con el motor JS (v4.html) usando un mismo generador mulberry32.
const fs=require('fs'),path=require('path');
const H=fs.readFileSync(process.argv[2],'utf8');
const a=H.indexOf('const CFG = {'), b=H.indexOf("if (typeof module !== 'undefined' && module.exports)");
let src=H.slice(a,b);
const exp=H.slice(b).split('\n')[1].replace('module.exports =','return');
const E=new Function(src+'\n'+exp)();
function mb(seed){let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};}
const N=+process.argv[4]||300, out=[];
for(let s=1;s<=N;s++){
  const R=mb(s*7919); Math.random=R;
  const bY=E.randomBuild(R), bF=E.randomBuild(R);
  const withMods=s%2===0;
  const shf=(a)=>{a=a.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(R()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;};
  const pickMods=(b)=>{const ids=E.MOD_IDS.filter(i=>E.MODS[i].part!=='spec'||E.MODS[i].robot===b.robot);b.mods=[];for(const i of shf(ids)){const t=b.mods.concat(i);if(b.mods.length<3&&!E.validBuild(Object.assign({},b,{mods:t})))b.mods=t;}};
  if(withMods){pickMods(bY);pickMods(bF);}
  const dY=E.DIFF_IDS[Math.floor(R()*3)], dF=E.DIFF_IDS[Math.floor(R()*3)];
  const g=E.newGame(bY,bF); E.applyDifficulty(g,dF);
  if(s%5===0){g.evAt=[5,10,15,20,25];}
  if(s%7===0){[g.you,g.foe].forEach(f=>{f.scNeed=4;f.arNeed=4;f.edge+=3;f.regen+=1;});}
  const rec={seed:s,bY,bF,dY,dF,evAt:g.evAt||null,ar:s%7===0,turns:[]};
  let guard=0;
  while(!g.over&&guard++<60){
    const t={mods:[]};
    if(g.foe.mods&&g.foe.mods.length)t.mods=E.bossUse(g,R).map(i=>'foe:'+i);
    if(g.you.mods&&g.you.mods.length){for(const id of g.you.mods){if(R()<0.15&&E.useMod(g,'you',id,R))t.mods.push('you:'+id);}}
    const pc=E.botPick(g.you,g.histFoe,R,dY,g.foe), bc=E.botPick(g.foe,g.hist,R,dF,g.you);
    t.pc=pc.id;t.bc=bc.id;
    const r=E.applyTurn(g,pc,bc);
    t.r=[r.toFoe,r.toYou,r.scYou,r.scFoe];
    const sn=f=>[f.hp,f.en,f.sc,f.edge||0,f.hand.map(c=>c.id).join(',')];
    t.y=sn(g.you);t.f=sn(g.foe);t.ev=g.ev?g.ev.id+':'+g.ev.left:'';t.evNext=g.evNext||'';t.turn=g.turn;
    rec.turns.push(t);
  }
  rec.result=g.result;rec.dealt=g.dealt;rec.taken=g.taken;
  out.push(rec);
}
fs.writeFileSync(process.argv[3],JSON.stringify(out));
const evs={};out.forEach(r=>r.turns.forEach(t=>{if(t.ev)evs[t.ev.split(':')[0]]=1;}));
console.log('partidas',out.length,'eventos vistos',Object.keys(evs).join(','),'mods usados',out.filter(r=>r.turns.some(t=>t.mods.length)).length);
