import Foundation

// MARK: - Self-contained interactive HTML diagrams for "Attention Is All You Need"
// Each string is loaded into a WKWebView via ConceptWebView (Path A: vizHtml).
// Height is reported back via window.webkit.messageHandlers.resize.postMessage().

enum AttentionDiagrams {

    // ──────────────────────────────────────────────────────────────────────────
    // 1. Token × Token Attention Heatmap
    //    Interactive 6×6 matrix. Tap a row to highlight that token's attention.
    // ──────────────────────────────────────────────────────────────────────────
    static let heatmap: String = #"""
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:transparent; font-family:-apple-system,system-ui; padding:12px 4px 10px; }
</style>
</head>
<body>
<div id="g"></div>
<script>
var T=['The','cat','sat','on','the','mat'];
var W=[
  [.82,.07,.04,.03,.02,.02],
  [.09,.68,.09,.05,.05,.04],
  [.03,.28,.43,.11,.09,.06],
  [.03,.05,.14,.70,.04,.04],
  [.42,.06,.05,.06,.35,.06],
  [.03,.11,.28,.06,.10,.42]
];
var teal='#1a8a8a', muted='#8a8f9a', active=null, cell=36;

function report() {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.resize)
    window.webkit.messageHandlers.resize.postMessage(document.body.scrollHeight);
}

function draw() {
  var h = '<div style="display:flex;margin-left:'+cell+'px;margin-bottom:3px;">';
  for (var j=0; j<T.length; j++)
    h += '<div style="width:'+cell+'px;font-size:8px;color:'+(active===j?teal:muted)+';text-align:center;font-weight:600;">'+T[j]+'</div>';
  h += '</div>';

  for (var i=0; i<W.length; i++) {
    h += '<div onclick="go('+i+')" style="display:flex;align-items:center;margin-bottom:2px;cursor:pointer;-webkit-tap-highlight-color:transparent;">';
    h += '<div style="width:'+cell+'px;font-size:8px;color:'+(active===i?teal:muted)+';font-weight:600;text-align:right;padding-right:5px;">'+T[i]+'</div>';
    for (var j=0; j<W[i].length; j++) {
      var w=W[i][j], hot=active===i;
      var a=(hot ? Math.min(w*1.35,.98) : w*.88).toFixed(2);
      var op=(active!==null && !hot) ? 0.3 : 1;
      h += '<div style="width:'+(cell-2)+'px;height:'+(cell-2)+'px;margin:1px;border-radius:4px;background:rgba(26,138,138,'+a+');opacity:'+op+';display:flex;align-items:center;justify-content:center;">';
      if (hot && w>.12) h += '<span style="font-size:7px;color:'+(w>.35?'white':teal)+';font-weight:700;">'+Math.round(w*100)+'</span>';
      h += '</div>';
    }
    h += '</div>';
  }

  var lbl = active!==null ? '\u201C'+T[active]+'\u201D attends \u2192' : 'tap a row';
  h += '<div style="display:flex;align-items:center;gap:6px;margin-top:10px;margin-left:'+cell+'px;">';
  h += '<div style="width:56px;height:6px;border-radius:3px;background:linear-gradient(to right,rgba(26,138,138,.05),rgba(26,138,138,.95));flex-shrink:0;"></div>';
  h += '<span style="font-size:8px;color:'+muted+';">low \u2192 high</span>';
  h += '<span style="margin-left:auto;font-size:8px;color:'+(active!==null?teal:muted)+';font-style:italic;">'+lbl+'</span>';
  h += '</div>';

  document.getElementById('g').innerHTML = h;
}

function go(i) { active=(active===i)?null:i; draw(); report(); }
draw();
setTimeout(report, 120);
</script>
</body>
</html>
"""#

    // ──────────────────────────────────────────────────────────────────────────
    // 2. Multi-Head Attention, 8 parallel heads
    //    Tap any head row to expand it and see which tokens it focuses on.
    // ──────────────────────────────────────────────────────────────────────────
    static let multiHead: String = #"""
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:transparent; font-family:-apple-system,system-ui; padding:10px 4px 10px; }
</style>
</head>
<body>
<div id="g"></div>
<script>
var teal='#1a8a8a', muted='#8a8f9a', tealLight='#e8f5f5';
var T=['The','cat','sat','on','the','mat'];
var H=[
  {n:'Syntax',  c:'#1a8a8a', p:[.80,.05,.10,.03,.01,.01], d:'subject\u2013verb agreement'},
  {n:'Coref',   c:'#e8a020', p:[.02,.04,.01,.04,.82,.07], d:'pronoun \u2192 noun links'},
  {n:'Semantic',c:'#7b4ba4', p:[.04,.72,.10,.04,.05,.05], d:'word meaning similarity'},
  {n:'Position',c:'#c0573c', p:[.01,.16,.70,.09,.03,.01], d:'adjacent word context'},
  {n:'Entity',  c:'#2d7abf', p:[.08,.02,.01,.01,.02,.86], d:'named entity focus'},
  {n:'Topic',   c:'#2a8a4a', p:[.19,.15,.14,.16,.19,.17], d:'global topic signal'},
  {n:'Dep',     c:'#8a4a1a', p:[.01,.02,.04,.01,.88,.04], d:'dependency structure'},
  {n:'Long',    c:'#5a1a8a', p:[.09,.01,.01,.01,.04,.84], d:'long-range context'},
];
var active=null;

function rgb(hex) {
  return parseInt(hex.slice(1,3),16)+','+parseInt(hex.slice(3,5),16)+','+parseInt(hex.slice(5,7),16);
}
function report() {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.resize)
    window.webkit.messageHandlers.resize.postMessage(document.body.scrollHeight);
}

function draw() {
  var h = '<div style="font-size:8px;font-weight:700;color:'+muted+';letter-spacing:.6px;text-align:center;margin-bottom:10px;text-transform:uppercase;">Tap a head to inspect</div>';
  for (var i=0; i<H.length; i++) {
    var head=H[i], isA=active===i, bh=isA?26:16;
    h += '<div onclick="go('+i+')" style="display:flex;align-items:center;gap:5px;margin-bottom:5px;cursor:pointer;-webkit-tap-highlight-color:transparent;">';
    h += '<div style="width:44px;font-size:7px;font-weight:700;color:'+(isA?head.c:muted)+';text-align:right;line-height:1.3;flex-shrink:0;">H'+(i+1)+'<br><span style=\'font-weight:400;\'>'+head.n+'</span></div>';
    for (var j=0; j<head.p.length; j++) {
      var w=head.p[j];
      h += '<div style="flex:1;height:'+bh+'px;border-radius:3px;background:rgba('+rgb(head.c)+','+(w*.92+.04).toFixed(2)+');display:flex;align-items:center;justify-content:center;overflow:hidden;">';
      if (isA && w>.2) h += '<span style="font-size:6px;color:white;font-weight:700;">'+T[j]+'</span>';
      h += '</div>';
    }
    h += '</div>';
  }
  if (active!==null) {
    var head=H[active];
    h += '<div style="margin-top:8px;padding:6px 10px;background:'+tealLight+';border-radius:8px;font-size:9px;color:'+teal+';font-weight:600;">';
    h += 'Head '+(active+1)+' \u00B7 <strong>'+head.n+'</strong>: learns '+head.d;
    h += '</div>';
  }
  document.getElementById('g').innerHTML = h;
}

function go(i) { active=(active===i)?null:i; draw(); setTimeout(report, 50); }
draw();
setTimeout(report, 120);
</script>
</body>
</html>
"""#

    // ──────────────────────────────────────────────────────────────────────────
    // 3. Positional Encoding, Sinusoidal Waves
    //    4 sine waves at different frequencies animate in on mount.
    // ──────────────────────────────────────────────────────────────────────────
    static let sineWaves: String = #"""
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:transparent; font-family:-apple-system,system-ui; padding:10px 4px 10px; }
</style>
</head>
<body>
<div id="g"></div>
<script>
var teal='#1a8a8a', muted='#8a8f9a', amber='#e8a020', tealLight='#e8f5f5';
var W=270, H=80;
var waves=[
  {f:1, c:teal,      lw:2.0, o:.95, lbl:'dim 0 (f=1\u00D7)'},
  {f:2, c:amber,     lw:1.6, o:.85, lbl:'dim 1 (f=2\u00D7)'},
  {f:4, c:'#7b4ba4', lw:1.4, o:.75, lbl:'dim 2 (f=4\u00D7)'},
  {f:8, c:'#2d7abf', lw:1.2, o:.65, lbl:'dim 3 (f=8\u00D7)'},
];
var prog=0, startTs=null;

function report() {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.resize)
    window.webkit.messageHandlers.resize.postMessage(document.body.scrollHeight);
}

function makePath(f, p) {
  var steps=Math.round(60*p);
  if (!steps) return '';
  var pts=[];
  for (var i=0; i<=steps; i++) {
    var x=(i/60)*W, y=H/2-Math.sin(i*f*Math.PI/30)*(H/2-10);
    pts.push((i===0?'M':'L')+x.toFixed(1)+','+y.toFixed(1));
  }
  return pts.join(' ');
}

function draw(p) {
  var grid='';
  for (var y=0; y<=H; y+=H/4)
    grid += '<line x1="0" y1="'+y+'" x2="'+W+'" y2="'+y+'" stroke="rgba(15,17,23,0.08)" stroke-width=".5"/>';
  var labels='';
  for (var i=0; i<=4; i++)
    labels += '<text x="'+(i*W/4)+'" y="'+(H+15)+'" font-size="8" fill="'+muted+'" text-anchor="middle">pos '+(i*15)+'</text>';
  var paths='';
  for (var i=0; i<waves.length; i++) {
    var wv=waves[i];
    paths += '<path d="'+makePath(wv.f,p)+'" stroke="'+wv.c+'" stroke-width="'+wv.lw+'" fill="none" stroke-opacity="'+wv.o+'" stroke-linecap="round"/>';
  }

  var legend='<div style="display:flex;flex-wrap:wrap;gap:6px 14px;margin-top:8px;">';
  for (var i=0; i<waves.length; i++) {
    var wv=waves[i];
    legend += '<div style="display:flex;align-items:center;gap:4px;">';
    legend += '<div style="width:14px;height:2.5px;border-radius:1px;background:'+wv.c+';opacity:'+wv.o+';"></div>';
    legend += '<span style="font-size:8px;color:'+muted+';">'+wv.lbl+'</span>';
    legend += '</div>';
  }
  legend += '</div>';

  document.getElementById('g').innerHTML =
    '<svg width="100%" viewBox="0 0 '+W+' '+(H+20)+'" style="overflow:visible;">' +
    grid + labels + paths + '</svg>' + legend;
}

function animate(ts) {
  if (!startTs) startTs=ts;
  prog=Math.min((ts-startTs)/1800, 1);
  draw(prog);
  if (prog<1) requestAnimationFrame(animate);
  else report();
}

draw(0);
report();
requestAnimationFrame(animate);
</script>
</body>
</html>
"""#

}
