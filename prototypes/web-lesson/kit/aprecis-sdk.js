/* Aprecis web-lesson SDK
 * Shipped once with the app (or cached from CDN). Every lesson bundle uses it
 * so the native↔web bridge, glossary, and card shell behave identically.
 *
 * Bridge messages (handled natively by WebLessonView.swift):
 *   haptic({style})  style ∈ soft|light|medium|heavy|rigid|select|success|warning|error
 *   markDone         mark this paper complete (feeds streak / daily goal)
 *   finish           mark complete + dismiss the reader
 *   close            dismiss the reader
 *   openOriginal({url})  present the source paper in an in-app browser
 */
(function (global) {
  function send(name, body) {
    var h = global.webkit && global.webkit.messageHandlers && global.webkit.messageHandlers[name];
    if (h) h.postMessage(body || {}); else console.log("[Aprecis]", name, body || "");
  }
  var Aprecis = {
    haptic: function (s) { send("haptic", { style: s || "soft" }); },
    select: function () { send("haptic", { style: "select" }); },
    success: function () { send("haptic", { style: "success" }); },
    markDone: function () { send("markDone"); },
    finish: function () { send("finish"); },
    close: function () { send("close"); },
    openOriginal: function (u) { send("openOriginal", { url: u }); },

    /* Mounts a lesson into #stage with the standard chrome: a segmented
     * progress rail, an N/total counter, exploration-gated advancement, themed
     * backgrounds, glossary taps, and edge-swipe-back.
     *
     * cards: [{ theme:'cover'|'paper'|'focus', label, gated?, html, init? }]
     * opts:  { glossary: { term: definition } }
     */
    mount: function (cards, opts) {
      opts = opts || {};
      var GLOSS = opts.glossary || {};
      var stage = document.getElementById("stage"),
          rail = document.getElementById("rail"),
          countEl = document.getElementById("count"),
          nextBtn = document.getElementById("next"),
          tryhint = document.getElementById("tryhint"),
          bg = document.getElementById("bg");
      var explored = new Set(), cur = 0;
      var THEME = {
        cover: { ink: "#f4f1ea", muted: "rgba(244,241,234,.62)" },
        paper: { ink: "#0f1117", muted: "#6b7078" },
        focus: { ink: "#0f1117", muted: "#6b7078" }
      };

      function markExplored(i) { explored.add(i); if (i === cur) refresh(); }
      global.markExplored = markExplored; // studios call this

      cards.forEach(function (c, i) {
        rail.insertAdjacentHTML("beforeend", '<div class="seg"></div>');
        var sec = document.createElement("section");
        sec.className = "card"; sec.dataset.idx = i; sec.innerHTML = c.html;
        stage.appendChild(sec);
        if (c.init) c.init(sec, i);
      });
      var sections = [].slice.call(stage.children), segs = [].slice.call(rail.children);

      function canAdvance() { var c = cards[cur]; return !c.gated || explored.has(cur); }
      function refresh() {
        var c = cards[cur], last = cur === cards.length - 1, ok = canAdvance();
        nextBtn.disabled = !ok;
        nextBtn.innerHTML = (last ? "Finish" : c.label) + ' <span class="ar">' + (last ? "✓" : "→") + "</span>";
        tryhint.style.display = (c.gated && !ok) ? "block" : "none";
      }
      function applyTheme(t) {
        bg.className = t; var v = THEME[t];
        document.documentElement.style.setProperty("--ink", v.ink);
        document.documentElement.style.setProperty("--themed-muted", v.muted);
      }
      function show(n) {
        sections.forEach(function (s, k) { s.classList.toggle("active", k === n); s.classList.toggle("back", k < n); });
        segs.forEach(function (s, k) { s.classList.toggle("on", k <= n); });
        countEl.textContent = (n + 1) + "/" + cards.length;
        cur = n; applyTheme(cards[n].theme); refresh(); sections[n].scrollTop = 0;
      }
      nextBtn.addEventListener("click", function () {
        Aprecis.haptic("medium");
        if (cur === cards.length - 1) { Aprecis.markDone(); Aprecis.finish(); return; }
        if (canAdvance()) show(cur + 1);
      });
      var closeBtn = document.getElementById("close");
      if (closeBtn) closeBtn.addEventListener("click", function () { Aprecis.haptic(); Aprecis.close(); });

      // glossary sheet
      var pop = document.getElementById("pop");
      if (pop) document.body.addEventListener("click", function (e) {
        var g = e.target.closest("[data-g]");
        if (g && g.dataset.g && GLOSS[g.dataset.g]) {
          document.getElementById("popT").textContent = g.dataset.g.charAt(0).toUpperCase() + g.dataset.g.slice(1);
          document.getElementById("popB").textContent = GLOSS[g.dataset.g];
          pop.classList.add("show"); Aprecis.haptic("light");
        } else if (e.target === pop) pop.classList.remove("show");
      });

      // edge-swipe back
      var sx = 0, sy = 0;
      stage.addEventListener("touchstart", function (e) { sx = e.touches[0].clientX; sy = e.touches[0].clientY; }, { passive: true });
      stage.addEventListener("touchend", function (e) {
        var dx = e.changedTouches[0].clientX - sx, dy = e.changedTouches[0].clientY - sy;
        if (sx < 32 && dx > 80 && Math.abs(dy) < 60 && cur > 0) { Aprecis.haptic(); show(cur - 1); }
      });

      show(0);
    }
  };
  global.Aprecis = Aprecis;
})(window);
